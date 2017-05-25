create or replace package body HCD_OWNER.health_fitness_upload as
  --== CONSTANTS ==--
  HTTP_VERSION_1_1  CONSTANT VARCHAR2(10):= UTL_HTTP.HTTP_VERSION_1_1;  -- 'HTTP/1.1'
  HTTP_OK           CONSTANT PLS_INTEGER := UTL_HTTP.HTTP_OK;           -- 200
  HTTP_CREATED      CONSTANT PLS_INTEGER := UTL_HTTP.HTTP_CREATED;      -- 201
  HTTP_BAD_REQUEST  CONSTANT PLS_INTEGER := UTL_HTTP.HTTP_BAD_REQUEST;  -- 400
  HTTP_UNAUTHORIZED CONSTANT PLS_INTEGER := UTL_HTTP.HTTP_UNAUTHORIZED; -- 401
  -- googlefit estimated steps
  -- steps dataSourceID/dataStreamId
  -- https://www.googleapis.com/fitness/v1/users/me/dataSources/derived:com.google.step_count.delta:com.google.android.gms:estimated_steps
---===============================================================
  PROCEDURE ERROR_QUEUE(p_report_cd varchar2, p_sqlerrm IN VARCHAR2, p_dml varchar2 default null) is
  pragma autonomous_transaction;
  BEGIN
    ROLLBACK;
--    vg_error_flag := 'Y';
--    vg_err_ctr    := vg_err_ctr + 1;
    INSERT INTO HCD_OWNER.EXTRACT_ERROR_QUEUE
      (EEQ_REPORT_CD, EEQ_ERROR_TEXT, EEQ_SQL_TEXT)
    VALUES
      (p_report_cd, SUBSTR(p_sqlerrm,1,200), p_dml);
  
    commit;
    DBMS_OUTPUT.PUT_LINE('Error=' || p_report_cd || '/' || p_sqlerrm);
  
  END ERROR_QUEUE;
---===============================================================
  FUNCTION https_call(
    p_body          VARCHAR2,
    p_url           VARCHAR2,
    p_operation     VARCHAR2,
    p_version       VARCHAR2,
    p_content_type  VARCHAR2,
    p_SOAP_action   VARCHAR2,
    p_accept        VARCHAR2,
    p_authorization VARCHAR2,
    p_resp          OUT UTL_HTTP.RESP)
  RETURN CLOB
IS
  http_req utl_http.req;
  http_resp utl_http.resp;
  l_clob CLOB;
  l_text VARCHAR2(32767);
  
BEGIN
  UTL_HTTP.set_wallet('file:/app/oracle/product/12.1.0.2/wallet', 'wallet1o1#');
  utl_http.set_transfer_timeout(30);
  http_req := utl_http.begin_request(p_url, p_operation, p_version);
  utl_http.set_header(http_req, 'Content-Type', p_content_type);
  IF p_SOAP_action IS NOT NULL THEN
    utl_http.set_header(http_req, 'SOAPAction', p_SOAP_action);
  END IF;

  IF p_accept IS NOT NULL THEN
    utl_http.set_header(http_req, 'Accept', p_accept);
  END IF;
  IF p_authorization IS NOT NULL THEN
    utl_http.set_header(http_req, 'Authorization',p_authorization);
  END IF;
  --
  IF p_body IS NOT NULL THEN
    utl_http.set_header(http_req, 'Content-Length', LENGTH(p_body));
  END IF;
  --
  utl_http.write_text(http_req, p_body);
  --
  http_resp := utl_http.get_response(http_req);
  --
  p_resp := http_resp;
  --
  --dbms_output.put_line(http_resp.status_code || '/' ||http_resp.reason_phrase || '/' || sqlerrm);
  IF (http_resp.status_code IN (HTTP_OK, HTTP_CREATED, HTTP_BAD_REQUEST,HTTP_UNAUTHORIZED)) THEN
    DBMS_LOB.createtemporary(l_clob, FALSE);
    BEGIN
      LOOP
        UTL_HTTP.read_text(http_resp, l_text, 300);
        l_text := REPLACE(l_text,'<![CDATA[','');
        --dbms_output.put_line(l_text);
        DBMS_LOB.writeappend(l_clob, LENGTH(l_text), l_text);
      END LOOP;
      UTL_HTTP.end_response(http_resp);
    EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      UTL_HTTP.end_response(http_resp);
      INSERT INTO hcd_owner.junk_clob
        (myclob
        )VALUES
        (l_clob
        );
      COMMIT;
    WHEN OTHERS THEN
      dbms_output.put_line(SUBSTR(sqlerrm, 1, 900));
      IF http_resp.HTTP_VERSION = 'UNSENT' THEN
        UTL_HTTP.END_REQUEST(http_req);
        --DBMS_OUTPUT.PUT_LINE('e1=UNSENT');
        error_queue('HTTPS_CALL', 'E1=UNSENT');
      ELSE
        IF dbms_lob.getlength(l_clob) = 0 THEN
          l_clob                     := sqlerrm;
        END IF;
        BEGIN
          UTL_HTTP.end_response(http_resp);
        EXCEPTION
        WHEN OTHERS THEN
          --DBMS_OUTPUT.PUT_LINE('e2=' || SQLERRM);
          error_queue('HTTPS_CALL', sqlerrm);
        END;
      END IF;
    END;
  ELSE
    IF http_resp.status_code='500' --and vg_dml='EpicGoogleFitQueue'
      THEN
      BEGIN
        LOOP
          UTL_HTTP.read_text(http_resp, l_text, 300);
          --dbms_output.put_line(l_text);
          DBMS_LOB.writeappend(l_clob, LENGTH(l_text), l_text);
        END LOOP;
        UTL_HTTP.end_response(http_resp);
      EXCEPTION
      WHEN UTL_HTTP.end_of_body THEN
        UTL_HTTP.end_response(http_resp);
        --insert into hcd_owner.junk_clob(myclob)values (l_clob);
        --commit;
      END;
    END IF;
  END IF;
  RETURN l_clob;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('e3=' || SQLERRM);
  error_queue('HTTPS_CALL', 'E3='||sqlerrm);
END https_call;
---===============================================================
  PROCEDURE LOG_JOB(p_start date ,p_err integer, p_cnt integer,p_report_cd varchar2) IS
  pragma autonomous_transaction;
  BEGIN
    INSERT INTO HCD_OWNER.EXTRACT_QUEUE_LOG
      (EQL_RUN_START_DT,
       EQL_RUN_END_DT,
       EQL_RECORD_ERROR_CNT,
       EQL_RECORD_PROCESS_CNT,
       EQL_REPORT_CD)
    VALUES
      (p_start, SYSDATE, p_err, p_cnt, p_report_cd);
    commit;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;
---===============================================================
  function has_errors (p_report_cd varchar2) return boolean is

    l_cnt integer := 0;

    cursor rec_cnt (cp_report_cd varchar2) is
      select count(*)
      from hcd_owner.extract_error_queue
      where eeq_report_cd = cp_report_cd;

    begin
      open rec_cnt(p_report_cd);
      fetch rec_cnt into l_cnt;
      close rec_cnt;
      
      return (l_cnt > 0);
      
    end has_errors;
---===============================================================
  function epoch_to_date(p_epoch in number) return date is
  begin
    return trunc(to_date('1970-01-01', 'YYYY-MM-DD') + (p_epoch / 86400));
  end epoch_to_date;
---===============================================================
  function date_to_epoch(in_date in date) return number is
    epoch    number(38);
    in_xdate date;
  begin
    --convert in_date to UTC
    select to_date(regexp_substr((cast(trunc(in_date) as timestamp) at time zone
                                  'UTC'),
                                 '[^.]+',
                                 1,
                                 1),
                   'dd-mon-yy hh24')
      into in_xdate
      from dual;
  
    select (in_xdate -
           to_date('1-1-1970 00:00:00', 'MM-DD-YYYY HH24:Mi:SS')) * 24 * 3600
      into epoch
      from dual;
    return epoch;
  exception
    when others then
      null;
  end date_to_epoch;
--==============================================================
  function epoch2date(p_epoch_secs in number) return date is
  begin
    return to_date('1970-01-01', 'YYYY-MM-DD') + numtodsinterval(p_epoch_secs,'second');
  end epoch2date;
---===============================================================
function date2epoch (p_dt date, p_timezone varchar2 default 'UTC') return number is

  cursor epoch_calc (cp_ts timestamp) is
    with calc_cur as(
      -- formula: TIMESTAMP (A) - INTERVAL (B)
      SELECT ( (A + 0) - (B + 0) ) * 24 * 60 * 60 as epch
        FROM
        ( 
         SELECT cast(cp_ts as timestamp) at time zone 'UTC' A,
                cast(cp_ts as timestamp) at time zone 'UTC' - 
                (cast(cp_ts as timestamp) at time zone 'UTC' - cast(TO_DATE('1970-01-01','YYYY-MM-DD') as timestamp) at time zone 'UTC') B
         FROM DUAL
--         SELECT cast(cp_ts as timestamp WITH LOCAL TIME ZONE) A,
--                cast(cp_ts as timestamp WITH LOCAL TIME ZONE)  - 
--                (cast(cp_ts as timestamp WITH LOCAL TIME ZONE) - cast(TO_DATE('1970-01-01','YYYY-MM-DD') as timestamp) ) B
--         FROM DUAL         
        )
    )
    SELECT epch,
           ROUND(epch) rnd_epch,
           TRUNC(epch) trnc_epch
    FROM calc_cur;
--
  l_epoch epoch_calc%rowtype;

begin
  open epoch_calc(cast(p_dt as timestamp));
  fetch epoch_calc into l_epoch;
  close epoch_calc;
--
--dbms_output.put_line(l_epoch.rnd_epch);
--
  return l_epoch.epch;

end date2epoch;
--==============================================================
function java_epoch_millis return number as language java name'java.lang.System.currentTimeMillis()return int';
--==============================================================
function java_dt2epoch (p_dt date) return number is
  epoch_now number := java_epoch_millis()/power(10,3);
  l_delta_secs number;
    
  begin
    -- seconds from now (delta)
    l_delta_secs := (sysdate - p_dt) * 86400;
  
    -- return delta secs + epoch now
    return l_delta_secs + epoch_now;
  end java_dt2epoch;
--==============================================================
  function get_emp_cred(p_epic_id      varchar2
                       ,p_epic_id_type varchar2) return emp_cred_t is
  l_post_body clob;
	l_cred_clob clob;
	l_emp_cred  emp_cred_t;
  l_resp utl_http.resp;

	begin
	  l_post_body := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Epic-com:Common.2012.Services.Patient">' ||
                   '<soapenv:Header/>' ||
                   '  <soapenv:Body>' ||
                   '  <urn:GetPatientIdentifiers>' ||
                   '    <urn:PatientID>'||p_epic_id||'</urn:PatientID>' ||
                   '    <urn:PatientIDType>'||p_epic_id_type||'</urn:PatientIDType>' ||
                   '  </urn:GetPatientIdentifiers>' ||
                   '  </soapenv:Body>' ||
                   '</soapenv:Envelope>';
      
	  DBMS_LOB.createtemporary(l_cred_clob, FALSE);

    l_cred_clob := https_call(p_body          => l_post_body
                             ,p_url           => 'https://estwepicint.csmc.edu/interconnect-bld-websvc/wcf/Epic.Common.GeneratedServices/Patient.svc/basic_2012'
                             ,p_operation     => 'POST'
                             ,p_version       => HTTP_VERSION_1_1
                             ,p_content_type  => 'text/xml'
                             ,p_soap_action   => 'urn:Epic-com:Common.2012.Services.Patient.GetPatientIdentifiers'
                             ,p_accept        => null
                             ,p_authorization => null
                             --
                             ,p_resp          => l_resp);

	  for ptid_xml in (SELECT idxtype, idx
           FROM XMLTABLE(XMLNAMESPACES(default 'urn:Epic-com:Common.2012.Services.Patient',
                              'http://schemas.xmlsoap.org/soap/envelope/' AS "s",
                              'http://www.w3.org/2001/XMLSchema-instance' as "i",
                              'urn:Epic-com:Common.2010.Services.Patient' as "a"),
                '//a:PatientIdentifier' passing
                (select xmltype(l_cred_clob) from dual)
				columns 
				idx varchar2(1000) path './a:ID',
        idxtype varchar2(1000) path './a:IDType')
                
        ) loop
--        if ptid_xml.idxtype='WPRINTERNAL' then l_emp_cred.WPRINTERNAL:= ptid_xml.idx; end if;
--        if ptid_xml.idxtype='CSMRN' then l_emp_cred.csmrn := ptid_xml.idx; end if;

		  case ptid_xml.idxtype
		    when 'WPRINTERNAL' then l_emp_cred.WPRINTERNAL := ptid_xml.idx;
		    when 'CSMRN'       then l_emp_cred.CSMRN       := ptid_xml.idx;
        else null;
		  end case;

    end loop; --ptid_xml
	 
	  return l_emp_cred;

	end get_emp_cred;
--==============================================================
  function get_episode_id(p_emp_cred emp_cred_t
                         ,p_entry_name varchar2) return varchar2 is
    
    l_post_body  clob;
    l_epis_clob  clob;
    l_episode_id varchar2(20);
    l_resp utl_http.resp;
    
    begin
	    null;
      l_post_body := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:epicsystems-com:PatientAccessMobile.2014.Services" >'||
                     '<soapenv:Header/>'||
                     '	<soapenv:Body>'||
                     '	<urn:GetFlowsheets>'||
                     '		<urn:PatientID>'||p_emp_cred.CSMRN||'</urn:PatientID> '||
                     '		<urn:PatientIDType>CSMRN</urn:PatientIDType>'||
                     '		<urn:MyChartAccountID>'||p_emp_cred.WPRINTERNAL||'</urn:MyChartAccountID>'||
                     '		<urn:MyChartAccountIDType>External</urn:MyChartAccountIDType>'||
                     '	</urn:GetFlowsheets>'||
                     '	</soapenv:Body>'||
                     '</soapenv:Envelope>';
            --dbms_output.put_line(post_body);
      DBMS_LOB.createtemporary(l_epis_clob, FALSE);
      
      l_epis_clob := https_call(p_body          => l_post_body
                               ,p_url           => 'https://estwepicint.csmc.edu/interconnect-bld-websvc/wcf/Epic.PatientAccessMobile.Services/PatientAccessMobile.svc/basic_2014'
                               ,p_operation     => 'POST'
                               ,p_version       => HTTP_VERSION_1_1
                               ,p_content_type  => 'text/xml'
                               ,p_soap_action   => 'urn:epicsystems-com:PatientAccessMobile.2014.Services.GetFlowsheets'
                               ,p_accept        => null
                               ,p_authorization => null
                             --
                               ,p_resp          => l_resp); 

      for flwsht_xml in (SELECT endDate,episodeIdtype,episodeId, entryName
                          FROM XMLTABLE(XMLNAMESPACES(default 'urn:epicsystems-com:PatientAccessMobile.2014.Services',
                              'http://schemas.xmlsoap.org/soap/envelope/' AS "s",
                              'http://www.w3.org/2001/XMLSchema-instance' as "i",
                              'http://schemas.datacontract.org/2004/07/Epic.PatientAccessMobile.SharedModels2014' as "a"
                              ),
                         '//Flowsheet' passing
                           (select xmltype(l_epis_clob) from dual) 
                                 columns endDate varchar2(1000) path './EndDate',
                                 episodeIdType varchar2(100) path './EpisodeIDType',
                                 episodeId varchar2(100) path './EpisodeID',
                                 entryName varchar2(100) path './Name')
                
                          ) loop

         if flwsht_xml.entryName = p_entry_name and flwsht_xml.Enddate is null then
           l_episode_id:= flwsht_xml.episodeid;
         end if;

      end loop; --flwsht_xml
      
      return l_episode_id;
      
    end get_episode_id;
--==============================================================
  function post_data(p_emp_cred     emp_cred_t
                    ,p_episode_id   varchar2
                    ,p_external_src varchar2
                    ,p_inst_tkn     varchar2
                    ,p_data         varchar2
                    ) return varchar2 is

  l_post_body clob;
	l_resp_clob clob;
  l_resp utl_http.resp;
  l_post_status varchar2(10);

  begin
	  null;
    l_post_body:= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'||
                  '<soapenv:Header/>'||
                  '<soapenv:Body>'||
                  '<AddFlowsheetReadings xmlns="urn:epicsystems-com:PatientAccessMobile.2014.Services" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'||
                  '<PatientID xsi:nil="false">'||p_emp_cred.CSMRN||'</PatientID>'||                                     
                  '<PatientIDType xsi:nil="false">CSMRN</PatientIDType>'||
                  '<MyChartAccountID xsi:nil="false">'||p_emp_cred.WPRINTERNAL||'</MyChartAccountID>'||
                  '<MyChartAccountIDType xsi:nil="false">External</MyChartAccountIDType>'||
                  '<EpisodeID xsi:nil="false">'||p_episode_id||'</EpisodeID>'||
                  '<EpisodeIDType xsi:nil="false">Internal</EpisodeIDType>'||
                  '<Readings xsi:nil="false">' ||
                  '<NewFlowsheetReading xsi:nil="false">'||
                  '<ExternalSource xsi:nil="false">'||p_external_src||'</ExternalSource>'||                                                  
                  '<InstantTaken xsi:nil="false">'||p_inst_tkn||'</InstantTaken>'||  
                     p_data ||
                  '</NewFlowsheetReading>'|| 
                  '</Readings>'||            
                  '</AddFlowsheetReadings>'||  
                  '</soapenv:Body>'||
                  '</soapenv:Envelope>';
	  
    DBMS_LOB.createtemporary(l_resp_clob, FALSE);
    
    l_resp_clob := https_call(p_body          => l_post_body
                             -->> substitute URL for environment specific logic??
                             ,p_url           => 'https://estwepicint.csmc.edu/interconnect-bld-websvc/wcf/Epic.PatientAccessMobile.Services/PatientAccessMobile.svc/basic_2014'
                             ,p_operation     => 'POST'
                             ,p_version       => HTTP_VERSION_1_1
                             ,p_content_type  => 'text/xml'
                             ,p_soap_action   => 'urn:epicsystems-com:PatientAccessMobile.2014.Services.AddFlowsheetReadings'
                             ,p_accept        => null
                             ,p_authorization => null
                             --
                             ,p_resp          => l_resp);

    for post_resp in (SELECT vstatus FROM
                      XMLTABLE(XMLNAMESPACES(
                      default 'urn:epicsystems-com:PatientAccessMobile.2014.Services',
                      'http://schemas.xmlsoap.org/soap/envelope/' AS "s",
                      'http://www.w3.org/2001/XMLSchema-instance' as "i"),
                      '//AddFlowsheetReadingsResult' passing
                      (select xmltype(l_resp_clob )from  dual) 
                      columns vstatus varchar2(1000) path './Status' ))loop

      l_post_status := post_resp.vstatus;

    end loop;
    
    return l_post_status;

  end post_data;
--==============================================================
  function get_google_access_token(p_client_id varchar2
                                  ,p_client_secret varchar2
                                  ,p_refresh_token varchar2
                                  ) return gfit_access_tkn_t is
    
    l_post_body  clob;
    l_token_clob clob;
    l_access_tkn gfit_access_tkn_t;
    l_resp utl_http.resp;
    
    begin
      
      l_post_body := 'myform' || chr(38) || 
                     'client_secret=' || p_client_secret || chr(38) ||
                     'grant_type=refresh_token' || chr(38) ||
                     'refresh_token=' || p_refresh_token || chr(38) ||
                     'client_id=' || p_client_id;
      
      DBMS_LOB.createtemporary(l_token_clob, FALSE);

      l_token_clob := https_call(p_body          => l_post_body
                                ,p_url           => 'https://www.googleapis.com/oauth2/v3/token'
                                ,p_operation     => 'POST'
                                ,p_version       => HTTP_VERSION_1_1
                                ,p_content_type  => 'application/x-www-form-urlencoded'
                                ,p_soap_action   => null
                                ,p_accept        => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                                ,p_authorization => null
                                ,p_resp          => l_resp);

      if l_resp.status_code = 200 then
        -- parse access token, token type, expiration interval
        l_access_tkn := null;

        FOR tkn_rec IN (SELECT atx, ttx, eix
               FROM json_table((select l_token_clob from dual),
               '$' COLUMNS(
                 atx PATH '$.access_token',
                 ttx PATH '$.token_type',
                 eix PATH '$.expires_in'))
                 ) LOOP

          l_access_tkn.access_token := tkn_rec.atx;
          l_access_tkn.token_type   := tkn_rec.ttx;
          l_access_tkn.expires_in   := tkn_rec.eix;

        end loop;


      end if;
      
      return l_access_tkn;
      
    end get_google_access_token;
--==============================================================
  function get_data_strm_id(p_token gfit_access_tkn_t
                           ,p_data_strm_nm varchar2) return varchar is
    
    l_resp utl_http.resp;
    l_data_ID_clob clob;
    l_data_strm_id varchar2(200);
    
    begin
      
      DBMS_LOB.createtemporary(l_data_ID_clob, FALSE);
      
      l_data_ID_clob :=  https_call(p_body          => null
                                   ,p_url           => 'https://www.googleapis.com/fitness/v1/users/me/dataSources'
                                   ,p_operation     => 'GET'
                                   ,p_version       => HTTP_VERSION_1_1
                                   ,p_content_type  => 'application/x-www-form-urlencoded'
                                   ,p_soap_action   => null
                                   ,p_accept        => 'application/json'
                                   ,p_authorization => p_token.token_type || ' ' || p_token.access_token
                                   ,p_resp          => l_resp);
    
      if l_resp.status_code = 200 then
        
        l_data_strm_id := '';
        
        for data_src in (select jt.dataStreamId
                     from json_table((select l_data_ID_clob from dual),
                     '$.dataSource[*]'
                     columns(
                     dataStreamId PATH '$.dataStreamId')
                     ) jt
                     ) loop

          if instr(data_src.datastreamId, p_data_strm_nm) > 0 then
            l_data_strm_id := data_src.datastreamId;
          end if;

        end loop;
      
      end if;
      
      return l_data_strm_id;
    
    end get_data_strm_id;
--==============================================================
  procedure upload_googlefit is
    ---
    cursor gfit_id_curs is
      select epic_id
            ,epic_id_type
            ,COUNT(*)
      from HCD_OWNER.epic_flowsheet_queue
      where process_dt IS NULL
        and api = 'CSHSGOOGLEFIT'
      group by epic_id
              ,epic_id_type;
    ---    
    cursor gfit_data_curs (cp_epic_id varchar2, cp_epic_id_type varchar2) is
      select *
      from HCD_OWNER.epic_flowsheet_queue
      where epic_id      = cp_epic_id
        and epic_id_type = cp_epic_id_type
        and process_dt is null
        --
 and efq_id = 1550
        --
        order by efq_id;
    ---
    l_emp_cred      emp_cred_t;
    l_episode_id    varchar2(20);
    l_proc          extract_error_queue.EEQ_REPORT_CD%type := 'GFITUPLD';
    --l_entry_name varchar2(100);
    l_instant_taken varchar2(30);
    l_data          varchar2(2000);
    l_post_status   varchar2(100);
    l_cnt integer := 0;
    --
    l_start date := sysdate;
    --
    begin

      
      for id_curs in gfit_id_curs LOOP
        
        --
        if has_errors(l_proc) then exit; end if;
        --
        l_emp_cred.csmrn := '';
        l_emp_cred := get_emp_cred(id_curs.epic_id,id_curs.epic_id_type);

        if l_emp_cred.CSMRN is null then
          ERROR_QUEUE(l_proc, 'Employee credentials not found for '||id_curs.epic_id||'/'||id_curs.epic_id_type);
        else
          l_episode_id := get_episode_id(l_emp_cred,'Personal Data Log');
          
          if l_episode_id is null then
            null;
            ERROR_QUEUE(l_proc, 'Episode ID not found for '||l_emp_cred.csmrn||'/'||l_emp_cred.wprinternal||'/'||'Personal Data Log');
          else
            for gfit_data in gfit_data_curs(id_curs.epic_id
                                           ,id_curs.epic_id_type) loop

              if (gfit_data.ndata is not null and gfit_data.ndata = 0) 
                  or (gfit_data.cdata is not null and length(gfit_data.cdata) = 0 ) then
              
                null; -- don't upload to epic
                
--                update hcd_owner.epic_flowsheet_queue
--                set process_dt = sysdate
--                where efq_id = gfit_data.efq_id;

              else
                begin
                
                  l_instant_taken := to_char(gfit_data.instant_taken,'yyyy-mm-dd');

                  if gfit_data.ndata is not null then
                    l_data := '<NumericValue xsi:nil="false">'||gfit_data.ndata||'</NumericValue>'||'<RowID xsi:nil="false">'||gfit_data.epic_rowid||'</RowID>';
                  end if;

                  -- post data to EPIC
                  l_post_status := post_data(l_emp_cred
                                            ,l_episode_id
                                            ,gfit_data.EXTERNAL_SOURCE
                                            ,l_instant_taken
                                            ,l_data
                                            );

                  if l_post_status != 'SUCCESS' then
                    ERROR_QUEUE(l_proc, 'Error posting to EPIC-'||l_post_status);
                    exit; -- exit or skip next record?
                  end if;

                exception
                  when others then
                    ERROR_QUEUE(l_proc, 'Error posting to EPIC-'||SQLERRM);
                    exit;
                end;

              end if;
              
              -- update row in the queue
              update hcd_owner.epic_flowsheet_queue
              set process_dt = sysdate
              where efq_id = gfit_data.efq_id;
              
              l_cnt := l_cnt + 1;

            end loop; -- data loop
            
          end if;
        end if;
      end loop; -- distinct emp id loop
      
      -- insert log entry
      log_job(l_start,0,l_cnt,l_proc);

    end upload_googlefit;
--==============================================================
  procedure upload_accuchek is
    begin
      null;
    end upload_accuchek;
--==============================================================
end health_fitness_upload;