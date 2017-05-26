create or replace package body health_api_pkg as
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
  function https_call(
    p_body          VARCHAR2,
    p_url           VARCHAR2,
    p_operation     VARCHAR2,
    p_version       VARCHAR2,
    p_content_type  VARCHAR2,
    p_SOAP_action   VARCHAR2,
    p_accept        VARCHAR2,
    p_authorization VARCHAR2) return RQST_RESP_T is

    http_req  utl_http.req;
    http_resp utl_http.resp;
    
    http_var RQST_RESP_T;
  
BEGIN
  UTL_HTTP.set_wallet('file:/app/oracle/product/12.1.0.2/wallet', 'wallet1o1#');

  utl_http.set_transfer_timeout(30);

  http_var.rqst := utl_http.begin_request(p_url, p_operation, p_version);

  utl_http.set_header(http_var.rqst, 'Content-Type', p_content_type);

  IF p_SOAP_action IS NOT NULL THEN
    utl_http.set_header(http_var.rqst, 'SOAPAction', p_SOAP_action);
  END IF;

  IF p_accept IS NOT NULL THEN
    utl_http.set_header(http_var.rqst, 'Accept', p_accept);
  END IF;

  IF p_authorization IS NOT NULL THEN
    utl_http.set_header(http_var.rqst, 'Authorization',p_authorization);
  END IF;
  --
  IF p_body IS NOT NULL THEN
    utl_http.set_header(http_var.rqst, 'Content-Length', LENGTH(p_body));
  END IF;
  --
  utl_http.write_text(http_var.rqst, p_body);
  --
  http_resp := utl_http.get_response(http_var.rqst);
  --
  RETURN http_var;
EXCEPTION
  WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('e3=' || SQLERRM);
  error_queue('HEALTH_API', sqlerrm, 'HTTPS_CALL');
END https_call;
---===============================================================
 function parse_resp(p_http in RQST_RESP_T) return clob is
 
    l_clob CLOB;
    l_text VARCHAR2(32767);
    l_resp utl_http.resp := p_http.resp;
    l_rqst utl_http.req  := p_http.rqst;
 begin
 
 DBMS_LOB.createtemporary(l_clob, FALSE);
  --dbms_output.put_line(l_resp.status_code || '/' ||l_resp.reason_phrase || '/' || sqlerrm);
  IF (l_resp.status_code IN (HTTP_OK, HTTP_CREATED, HTTP_BAD_REQUEST, HTTP_UNAUTHORIZED)) THEN
--    DBMS_LOB.createtemporary(l_clob, FALSE);
    BEGIN
      LOOP
        UTL_HTTP.read_text(l_resp, l_text, 300);
        l_text := REPLACE(l_text,'<![CDATA[','');
        --dbms_output.put_line(l_text);
        DBMS_LOB.writeappend(l_clob, LENGTH(l_text), l_text);
      END LOOP;
      UTL_HTTP.end_response(l_resp);
    EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      UTL_HTTP.end_response(l_resp);
--      INSERT INTO hcd_owner.junk_clob
--        (myclob
--        )VALUES
--        (l_clob
--        );
--      COMMIT;
    WHEN OTHERS THEN
      dbms_output.put_line(SUBSTR(sqlerrm, 1, 900));
      IF l_resp.HTTP_VERSION = 'UNSENT' THEN
        UTL_HTTP.END_REQUEST(l_rqst);
        --DBMS_OUTPUT.PUT_LINE('e1=UNSENT');
        error_queue('HTTPS_CALL', 'E1=UNSENT');
      ELSE
        IF dbms_lob.getlength(l_clob) = 0 THEN
          l_clob := sqlerrm;
        END IF;
        BEGIN
          UTL_HTTP.end_response(l_resp);
        EXCEPTION
        WHEN OTHERS THEN
          --DBMS_OUTPUT.PUT_LINE('e2=' || SQLERRM);
          error_queue('HTTPS_CALL', 'E2=' ||sqlerrm);
        END;
      END IF;
    END;
  ELSE
    IF l_resp.status_code='500' --and vg_dml='EpicGoogleFitQueue'
      THEN
      BEGIN
        LOOP
          UTL_HTTP.read_text(l_resp, l_text, 300);
          --dbms_output.put_line(l_text);
          DBMS_LOB.writeappend(l_clob, LENGTH(l_text), l_text);
        END LOOP;
        UTL_HTTP.end_response(l_resp);
      EXCEPTION
      WHEN UTL_HTTP.end_of_body THEN
        UTL_HTTP.end_response(l_resp);
        --insert into hcd_owner.junk_clob(myclob)values (l_clob);
        --commit;
      END;
    END IF;

  END IF;

  RETURN l_clob;

  EXCEPTION
    WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('e3=' || SQLERRM);
      error_queue('HEALTH_API', sqlerrm, 'PARSE_RESP');
  end parse_resp;

end health_api_pkg;