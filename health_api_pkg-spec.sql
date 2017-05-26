create or replace package health_api_pkg as
  --== TYPES ==--
  type RQST_RESP_T is record (rqst utl_http.req,resp utl_http.resp);
--
  function https_call(
    p_body          VARCHAR2,
    p_url           VARCHAR2,
    p_operation     VARCHAR2,
    p_version       VARCHAR2,
    p_content_type  VARCHAR2,
    p_SOAP_action   VARCHAR2,
    p_accept        VARCHAR2,
    p_authorization VARCHAR2) RETURN RQST_RESP_T;

 function parse_resp(p_http in RQST_RESP_T) return clob;

end health_api_pkg;