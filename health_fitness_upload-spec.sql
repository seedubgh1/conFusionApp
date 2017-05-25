create or replace package HCD_OWNER.health_fitness_upload as
  type emp_cred_t is record (csmrn varchar2(50), wprinternal varchar2(50));
  type gfit_access_tkn_t is record (access_token hcd_owner.epic_flowsheet_candidates.access_token%type
                                   ,token_type    varchar2(100)
                                   ,expires_in    varchar2(10)
                                   );
  
  function get_emp_cred(p_epic_id varchar2, p_epic_id_type varchar2) return emp_cred_t;

  function get_episode_id(p_emp_cred emp_cred_t
                         ,p_entry_name varchar2) return varchar2;

  function get_google_access_token(p_client_id varchar2
                                  ,p_client_secret varchar2
                                  ,p_refresh_token varchar2
                                  ) return gfit_access_tkn_t;
  
  function get_data_strm_id(p_token gfit_access_tkn_t
                           ,p_data_strm_nm varchar2) return varchar;
  
  function post_data(p_emp_cred     emp_cred_t
                    ,p_episode_id   varchar2
                    ,p_external_src varchar2
                    ,p_inst_tkn     varchar2
                    ,p_data         varchar2
                    ) return varchar2;

  procedure upload_googlefit;

  procedure upload_accuchek;
  
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
  RETURN CLOB;
  
  function epoch_to_date(p_epoch in number)   return date;
  function date_to_epoch(in_date in date) return number;
  --
  function epoch2date(p_epoch_secs in number) return date;
  function date2epoch (p_dt date, p_timezone varchar2 default 'UTC') return number;
  function java_epoch_millis return number;
  function java_dt2epoch (p_dt date) return number;

end health_fitness_upload;