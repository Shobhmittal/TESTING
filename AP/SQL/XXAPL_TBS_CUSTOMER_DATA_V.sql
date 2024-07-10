CREATE OR REPLACE FORCE VIEW APPS.XXAPL_TBS_CUSTOMER_DATA_V
(
   CUST_NAME,
   ACCOUNT_NUMBER,
   CUST_ACCOUNT_ID,
   SITE_USE_ID, --CR#3-2
   SITE_USE_ID,
   LOCATION,  --CR#4-1
   BILL_TO_LOCATION,
   GOVID,
   PRIMARY_FLAG,
   CUST_ACCT_SITE_ID_SHIP,
   CUST_ACCT_SITE_ID_BILL,
   PRIMARY_SALESREP_ID,
   PAYMENT_TERM_ID_BILL
)
AS
   SELECT NVL (hca.account_name, hp.party_name) cust_name,
          hca.account_number,
          hca.cust_account_id,
          hcsu.site_use_id,
          hcsu.LOCATION,
          hcsub.LOCATION bill_to_location,
          hcsu.attribute13 govid,
          hcsu.primary_flag,
          hcas.cust_acct_site_id cust_acct_site_id_ship,
          hcas_bill.cust_acct_site_id cust_acct_site_id_bill,
          hcsu.primary_salesrep_id,
          pmt.term_id payment_term_id_bill
     FROM hz_cust_site_uses_all hcsu,
          hz_cust_site_uses_all hcsub,
          hz_cust_accounts_all hca,
          hz_cust_acct_sites_all hcas,
          hz_parties hp,
          hz_cust_acct_sites_all hcas_bill,
          (SELECT TERM_ID
             FROM RA_TERMS_VL
            WHERE NAME = 'Pmt to Follow' AND In_USE = 'Y') pmt
    WHERE     hcsu.site_use_code = 'SHIP_TO'
          AND hcsu.bill_to_site_use_id = hcsub.site_use_id(+)
          AND hcsu.cust_acct_site_id = hcas.cust_acct_site_id(+)
          AND hcas.cust_account_id = hca.cust_account_id(+)
          AND hca.party_id = hp.party_id(+)
          AND hcsub.site_use_code(+) = 'BILL_TO'
          AND hcsub.status(+) = 'A'
          AND hcas_bill.cust_acct_site_id(+) = hcsub.cust_acct_site_id
          AND hcas_bill.status(+) = 'A'
          AND hca.status = 'A'
/		  