CREATE OR REPLACE PACKAGE APPS.REGN_ASSET_DETAILS_REPORT_PKG
AS
/* 23-Aug-2016 - Shobhit Mittal - Modified package for  Ticket# 758984 */
PROCEDURE LIST_ASSETS ( ERRBUF           IN OUT  VARCHAR2
                      , RETCODE          IN OUT  VARCHAR2
                      , P_BOOK           IN      VARCHAR2
                      , P_PERIOD         IN      VARCHAR2
                      , P_FLAG           IN      VARCHAR2
					  );

END REGN_ASSET_DETAILS_REPORT_PKG ;
/

CREATE OR REPLACE PACKAGE BODY APPS.REGN_ASSET_DETAILS_REPORT_PKG
AS
/* 9/9/2013 - Jerry Conticchio - Increased Company Segment to 4 characters and added Intercompany Segment */
/* 4-mar-2014 - rreyes - added fields attribute9 and 10 from fa_additions for cpt project*/
/* 28-Oct-2014 - Kalpit Sharma - Added Assest Book Name for Ticket# 521536 */
/* 23-Aug-2016 - Shobhit Mittal - Modified package for  Ticket# 758984 */
  PROCEDURE LIST_ASSETS (
             ERRBUF             IN OUT  VARCHAR2
           , RETCODE            IN OUT  VARCHAR2
           , P_BOOK             IN   VARCHAR2
           , P_PERIOD           IN   VARCHAR2
           , P_FLAG             IN   VARCHAR2                  )

  IS
   
   v_ucd DATE;
   v_upc NUMBER;
   V_tod DATE;
  
  --ADDED BY SM 23-AUG-2016
  CURSOR c_assets_zero_cost(p_book_type_code VARCHAR2,p_tod DATE, p_ucd DATE,p_upc NUMBER) IS
  SELECT /*+ ORDERED
                   Index(DD1 FA_DEPRN_DETAIL_N1)
           Index(DD_BONUS FA_DEPRN_DETAIL_U1)
           index(DH FA_DISTRIBUTION_HISTORY_U1)
           Index(AH FA_ASSET_HISTORY_N2)
       */
        fa  .asset_number
         || '|'
         || SUBSTR (cb.asset_cost_acct, 1, 5)
         || '|'
         || SUBSTR (gcc.segment1, 1, 4)
         || '|'
         || SUBSTR (gcc.segment2, 1, 4)
         || '|'
         || SUBSTR (gcc.segment3, 1, 5)
         || '|'
         || SUBSTR (gcc.segment4, 1, 12)
         || '|'
         || SUBSTR (gcc.segment5, 1, 5)
         || '|'
         || SUBSTR (gcc.segment6, 1, 5)
         || '|'
         || SUBSTR (gcc.segment7, 1, 4)
         || '|'
         || TRIM (fa.attribute_category_code)
         || '|'
         || books.date_placed_in_service
         || '|'
         || fl.segment1
         || '-'
         || fl.segment2
         || '-'
         || fl.segment3
         || '-'
         || fl.segment4
         || '|'
         || fl.segment1
         || '|'
         || fl.segment2
         || '|'
         || fl.segment3
         || '|'
         || fl.segment4
         || '|'
         || fa.manufacturer_name
         || '|'
         || fa.model_number
         || '|'
         || fa.serial_number
         || '|'
         || fa.tag_number
         || '|'
         || ppf.full_name
         || '|'
         || SUM (dd_bonus.COST)
         || '|'
         || SUM (dd_bonus.deprn_reserve - dd_bonus.bonus_deprn_reserve)
         || '|'
         || (SUM (dd_bonus.COST)-SUM (dd_bonus.deprn_reserve - dd_bonus.bonus_deprn_reserve))
         || '|'
         || books.life_in_months
         || '|'
         || FLOOR (books.life_in_months / 12)
         || '|'
         || mod(books.life_in_months, 12)
         || '|'
         || fa.owned_leased
         || '|'
         || REGEXP_REPLACE (fa.description, '[\|"]|([[:cntrl:]])', ' ')
         || '|'
         || NVL (fa.attribute10, '999999')
         || '|'
         || ffvt.description
         || '|'
         || fbc.book_type_name
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   2,
                                                   SUBSTR (gcc.segment2, 1, 4))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   3,
                                                   SUBSTR (gcc.segment3, 1, 5))
         || '|'
         || gl_flexfields_pkg.get_description_sql (
               gcc.chart_of_accounts_id,
               4,
               SUBSTR (gcc.segment4, 1, 12))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   5,
                                                   SUBSTR (gcc.segment5, 1, 5))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   6,
                                                   SUBSTR (gcc.segment6, 1, 5))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   7,
                                                   SUBSTR (gcc.segment7, 1, 4))
         || '|'
         || fa.asset_type
            AS STRING
    FROM (  SELECT distribution_id, MAX (period_counter) period_counter
              FROM fa_deprn_detail
             WHERE book_type_code = p_book_type_code AND period_counter <= p_upc
          GROUP BY distribution_id) dd1,
         fa_deprn_detail dd_bonus,
         fa_distribution_history dh,
         fa_asset_history ah,
         fa_books books,
         fa_transaction_headers th_rt,
         fa_category_books cb,
         fa_additions fa,
         gl_code_combinations_kfv gcc,
         fa_locations fl,
         fa_book_controls fbc,
         fa_categories fc,
         fa_asset_keywords fak,
         per_people_f ppf,
         fnd_flex_values ffv,
         fnd_flex_values_tl ffvt,
         fnd_flex_value_sets ffvs
   WHERE     books.book_type_code = p_book_type_code
         AND fa.asset_id = dd_bonus.asset_id
         AND books.asset_id = dd_bonus.asset_id
         AND books.date_effective <= p_ucd
         AND NVL (books.date_ineffective, SYSDATE + 1) > p_ucd
         AND cb.book_type_code = books.book_type_code
         AND cb.category_id = ah.category_id
         AND ah.asset_id = dd_bonus.asset_id
         AND dd_bonus.book_type_code = books.book_type_code
         AND dd_bonus.distribution_id = dh.distribution_id
         AND dd_bonus.distribution_id = dd1.distribution_id
         AND dd_bonus.period_counter = dd1.period_counter
         AND ah.date_effective < p_ucd
         AND NVL (ah.date_ineffective, SYSDATE) >= p_ucd
         AND th_rt.book_type_code = books.book_type_code
         AND th_rt.transaction_header_id = books.transaction_header_id_in
         AND dh.book_type_code = p_book_type_code
         AND dh.date_effective <= p_ucd
         AND NVL (dh.date_ineffective, SYSDATE) > p_tod
         AND gcc.code_combination_id = dh.code_combination_id
         AND fl.location_id(+) = dh.location_id
         AND fc.category_id(+) = fa.asset_category_id
         AND fak.code_combination_id(+) = fa.asset_key_ccid
         AND ppf.person_id(+) = dh.assigned_to
         AND ppf.effective_start_date(+) <= TRUNC (SYSDATE)
         AND ppf.effective_end_date(+) >= TRUNC (SYSDATE)
         AND fbc.book_type_code(+) = books.book_type_code
         AND ffvs.flex_value_set_name = 'REGN_CPT_PROJECT_IDS'
         AND ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffv.flex_value = NVL (fa.attribute10, '999999')
GROUP BY fa.asset_number,
         SUBSTR (cb.asset_cost_acct, 1, 5),
         SUBSTR (gcc.segment1, 1, 4),
         SUBSTR (gcc.segment2, 1, 4),
         SUBSTR (gcc.segment3, 1, 5),
         SUBSTR (gcc.segment4, 1, 12),
         SUBSTR (gcc.segment5, 1, 5),
         SUBSTR (gcc.segment6, 1, 5),
         SUBSTR (gcc.segment7, 1, 4),
         TRIM (fa.attribute_category_code),
         books.date_placed_in_service,
         fl.segment1,
         fl.segment2,
         fl.segment3,
         fl.segment4,
         fa.manufacturer_name,
         fa.model_number,
         fa.serial_number,
         fa.tag_number,
         ppf.full_name,
         books.life_in_months,
         books.life_in_months / 12,
         REMAINDER (books.life_in_months, 12),
         fa.owned_leased,
         REGEXP_REPLACE (fa.description, '[\|"]|([[:cntrl:]])', ' '),
         NVL (fa.attribute10, '999999'),
         ffvt.description,
         fbc.book_type_name,
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                2,
                                                SUBSTR (gcc.segment2, 1, 4)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                3,
                                                SUBSTR (gcc.segment3, 1, 5)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                4,
                                                SUBSTR (gcc.segment4, 1, 12)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                5,
                                                SUBSTR (gcc.segment5, 1, 5)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                6,
                                                SUBSTR (gcc.segment6, 1, 5)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                7,
                                                SUBSTR (gcc.segment7, 1, 4)),
         fa.asset_type;

--COMMENTED BY SM 23-AUG-2016         
/*         select         addr.asset_number                               || '|' ||
                SUBSTR(cat.asset_cost_acct, 1, 5)               || '|' ||
                SUBSTR(glcc.segment1, 1, 4)                     || '|' ||  -- Increased Company segment to 4 characters - GC
                SUBSTR(glcc.segment2, 1, 4)                     || '|' ||
                SUBSTR(glcc.segment3, 1, 5)                     || '|' ||
                SUBSTR(glcc.segment4, 1, 12)                    || '|' ||
                SUBSTR(glcc.segment5, 1, 5)                     || '|' ||
                SUBSTR(glcc.segment6, 1, 5)                     || '|' ||
                SUBSTR(glcc.segment7, 1, 4)                     || '|' ||   -- Added Intercompany segment - GC
                addr.attribute_category_code                    || '|' ||
                books.date_placed_in_service                    || '|' ||
                fal.segment1   ||'-'||  fal.segment2  ||'-'|| fal.segment3  ||'-'|| fal.segment4                                   || '|' ||
                  fal.segment1                                  || '|' ||
                 fal.segment2                                   || '|' ||
                 fal.segment3                                   || '|' ||
                 fal.segment4                                   || '|' ||
                addr.manufacturer_name                          || '|' ||
                addr.model_number                               || '|' ||
                addr.serial_number                              || '|' ||
                addr.tag_number                                 || '|' ||
                (select full_name  from per_all_people_f  where person_id = dist_hist.ASSIGNED_TO and effective_start_date <= p_from  and effective_end_date > p_to )      || '|' ||
                books.cost                                      || '|' ||
                sum(det.deprn_reserve)                          || '|' ||
           ( books.cost   -   sum(det.deprn_reserve))           || '|' ||
                books.life_in_months                            || '|' ||
                books.life_in_months/12                         || '|' ||
                remainder(books.life_in_months,12)              || '|' ||
                addr.owned_leased                               || '|' ||
                regexp_replace(addr.description,  '[\|"]|([[:cntrl:]])',' ')       || '|' || --modified rreyes to include replacement   --of pipe and nonprintable along with quote
                nvl(addr.attribute10,'999999')                  || '|' || --added rreyes cpt
                ffvt.description                                || '|' || --added rreyes cpt
                fbc.book_type_name                              || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 2,SUBSTR(glcc.segment2, 1, 4) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 3,SUBSTR(glcc.segment3, 1, 5) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 4,SUBSTR(glcc.segment4, 1, 12))                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 5,SUBSTR(glcc.segment5, 1, 5) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 6,SUBSTR(glcc.segment6, 1, 5) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 7,SUBSTR(glcc.segment7, 1, 4) )                    || '|' ||
                addr.asset_type                
                STRING
        from fa_book_controls fbc,
                fa_additions            addr     ,
                fa_asset_history        hist     ,
                fa_category_books       cat      ,
                fa_books                books    ,
                fa_distribution_history dist_hist,
                gl_code_combinations    glcc     ,
                fa_deprn_detail         det      ,
                fa_locations            fal      ,
                fnd_flex_values         ffv      ,      -- added rreyes cpt
                fnd_flex_values_tl      ffvt     ,      -- added rreyes cpt
                fnd_flex_value_sets     ffvs            -- added rreyes cpt
        where   period_counter              = (select max(period_counter)   from fa_deprn_detail where asset_id =  det.asset_id)
        and     addr.asset_id               = books.asset_id
        and     det.asset_id                = books.asset_id
        and     fbc.book_type_code(+) = books.book_type_code
        and     addr.asset_id               = hist.asset_id
        and     det.book_type_code          = cat.book_type_code --added to fix issue with multiple books since implmenting ireland sub INC0043789
        and     hist.category_id            = cat.category_id
        and     dist_hist.asset_id          = books.asset_id
        and     glcc.code_combination_id    = dist_hist.code_combination_id
        and     dist_hist.date_effective    <= p_from and nvl(dist_hist.date_ineffective, p_to) >= p_to
        and     books.date_effective        <= p_from and nvl(books.date_ineffective, p_to) >= p_to
        and     hist.date_effective         <= p_from and nvl(hist.date_ineffective, p_to) >= p_to
        and     dist_hist.location_id       = fal.location_id
        and     ffvs.flex_value_set_name    = 'REGN_CPT_PROJECT_IDS'        -- added rreyes cpt
        and     ffv.flex_value_set_id       = ffvs.flex_value_set_id        -- added rreyes cpt
        and     ffv.flex_value_id           = ffvt.flex_value_id            -- added rreyes cpt
        and     ffv.flex_value              = nvl(addr.attribute10, '999999') -- added rreyes cpt
        and     books.book_type_code        = NVL(P_BOOK,books.book_type_code)
        group by
                substr(cat.asset_cost_acct, 1, 5)  ,
                substr(glcc.segment1, 1, 4) ,    -- Increased Company segment to 4 characters - GC
                substr(glcc.segment2, 1, 4) ,
                substr(glcc.segment3, 1, 5) ,
                substr(glcc.segment4, 1, 12)  ,
                substr(glcc.segment5, 1, 5) ,
                substr(glcc.segment6, 1, 5)  ,
                substr(glcc.segment7, 1, 4)  ,  -- Added Intercompany segment - GC
                addr.asset_number               ,
                regexp_replace(addr.description, '[\|"]|([[:cntrl:]])',' '),
                addr.attribute_category_code     ,
                books.date_placed_in_service      ,
                fal.segment1, fal.segment2, fal.segment3, fal.segment4     ,
                addr.manufacturer_name ,
                addr.model_number ,
                addr.serial_number ,
                addr.tag_number   ,
                dist_hist.assigned_to,
                books.cost,
                books.life_in_months,
                addr.owned_leased,
                nvl(addr.attribute10,'999999'),
                ffvt.description,
                fbc.book_type_name,
                glcc.chart_of_accounts_id ,
                addr.asset_type;   

*/

--ADDED BY SM 23-AUG-2016
  CURSOR c_assets_non_zero_cost(p_book_type_code VARCHAR2,p_tod DATE, p_ucd DATE,p_upc NUMBER) IS
  SELECT /*+ ORDERED
                   Index(DD1 FA_DEPRN_DETAIL_N1)
           Index(DD_BONUS FA_DEPRN_DETAIL_U1)
           index(DH FA_DISTRIBUTION_HISTORY_U1)
           Index(AH FA_ASSET_HISTORY_N2)
       */
        fa  .asset_number
         || '|'
         || SUBSTR (cb.asset_cost_acct, 1, 5)
         || '|'
         || SUBSTR (gcc.segment1, 1, 4)
         || '|'
         || SUBSTR (gcc.segment2, 1, 4)
         || '|'
         || SUBSTR (gcc.segment3, 1, 5)
         || '|'
         || SUBSTR (gcc.segment4, 1, 12)
         || '|'
         || SUBSTR (gcc.segment5, 1, 5)
         || '|'
         || SUBSTR (gcc.segment6, 1, 5)
         || '|'
         || SUBSTR (gcc.segment7, 1, 4)
         || '|'
         || TRIM (fa.attribute_category_code)
         || '|'
         || books.date_placed_in_service
         || '|'
         || fl.segment1
         || '-'
         || fl.segment2
         || '-'
         || fl.segment3
         || '-'
         || fl.segment4
         || '|'
         || fl.segment1
         || '|'
         || fl.segment2
         || '|'
         || fl.segment3
         || '|'
         || fl.segment4
         || '|'
         || fa.manufacturer_name
         || '|'
         || fa.model_number
         || '|'
         || fa.serial_number
         || '|'
         || fa.tag_number
         || '|'
         || ppf.full_name
         || '|'
         || SUM (dd_bonus.COST)
         || '|'
         || SUM (dd_bonus.deprn_reserve - dd_bonus.bonus_deprn_reserve)
         || '|'
         || (SUM (dd_bonus.COST)-SUM (dd_bonus.deprn_reserve - dd_bonus.bonus_deprn_reserve))
         || '|'
         || books.life_in_months
         || '|'
         || FLOOR (books.life_in_months / 12)
         || '|'
         || mod(books.life_in_months, 12)
         || '|'
         || fa.owned_leased
         || '|'
         || REGEXP_REPLACE (fa.description, '[\|"]|([[:cntrl:]])', ' ')
         || '|'
         || NVL (fa.attribute10, '999999')
         || '|'
         || ffvt.description
         || '|'
         || fbc.book_type_name
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   2,
                                                   SUBSTR (gcc.segment2, 1, 4))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   3,
                                                   SUBSTR (gcc.segment3, 1, 5))
         || '|'
         || gl_flexfields_pkg.get_description_sql (
               gcc.chart_of_accounts_id,
               4,
               SUBSTR (gcc.segment4, 1, 12))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   5,
                                                   SUBSTR (gcc.segment5, 1, 5))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   6,
                                                   SUBSTR (gcc.segment6, 1, 5))
         || '|'
         || gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                   7,
                                                   SUBSTR (gcc.segment7, 1, 4))
         || '|'
         || fa.asset_type
            AS STRING
    FROM (  SELECT distribution_id, MAX (period_counter) period_counter
              FROM fa_deprn_detail
             WHERE book_type_code = p_book_type_code AND period_counter <= p_upc
          GROUP BY distribution_id) dd1,
         fa_deprn_detail dd_bonus,
         fa_distribution_history dh,
         fa_asset_history ah,
         fa_books books,
         fa_transaction_headers th_rt,
         fa_category_books cb,
         fa_additions fa,
         gl_code_combinations_kfv gcc,
         fa_locations fl,
         fa_book_controls fbc,
         fa_categories fc,
         fa_asset_keywords fak,
         per_people_f ppf,
         fnd_flex_values ffv,
         fnd_flex_values_tl ffvt,
         fnd_flex_value_sets ffvs
   WHERE     books.book_type_code = p_book_type_code
         AND fa.asset_id = dd_bonus.asset_id
         AND books.asset_id = dd_bonus.asset_id
         AND books.date_effective <= p_ucd
         AND NVL (books.date_ineffective, SYSDATE + 1) > p_ucd
         AND cb.book_type_code = books.book_type_code
         AND cb.category_id = ah.category_id
         AND ah.asset_id = dd_bonus.asset_id
         AND dd_bonus.book_type_code = books.book_type_code
         AND dd_bonus.distribution_id = dh.distribution_id
         AND dd_bonus.distribution_id = dd1.distribution_id
         AND dd_bonus.period_counter = dd1.period_counter
         AND ah.date_effective < p_ucd
         AND NVL (ah.date_ineffective, SYSDATE) >= p_ucd
         AND th_rt.book_type_code = books.book_type_code
         AND th_rt.transaction_header_id = books.transaction_header_id_in
         AND dh.book_type_code = p_book_type_code
         AND dh.date_effective <= p_ucd
         AND NVL (dh.date_ineffective, SYSDATE) > p_tod
         AND gcc.code_combination_id = dh.code_combination_id
         AND fl.location_id(+) = dh.location_id
         AND fc.category_id(+) = fa.asset_category_id
         AND fak.code_combination_id(+) = fa.asset_key_ccid
         AND ppf.person_id(+) = dh.assigned_to
         AND ppf.effective_start_date(+) <= TRUNC (SYSDATE)
         AND ppf.effective_end_date(+) >= TRUNC (SYSDATE)
         AND fbc.book_type_code(+) = books.book_type_code
         AND ffvs.flex_value_set_name = 'REGN_CPT_PROJECT_IDS'
         AND ffv.flex_value_set_id = ffvs.flex_value_set_id
         AND ffv.flex_value_id = ffvt.flex_value_id
         AND ffv.flex_value = NVL (fa.attribute10, '999999')
GROUP BY fa.asset_number,
         SUBSTR (cb.asset_cost_acct, 1, 5),
         SUBSTR (gcc.segment1, 1, 4),
         SUBSTR (gcc.segment2, 1, 4),
         SUBSTR (gcc.segment3, 1, 5),
         SUBSTR (gcc.segment4, 1, 12),
         SUBSTR (gcc.segment5, 1, 5),
         SUBSTR (gcc.segment6, 1, 5),
         SUBSTR (gcc.segment7, 1, 4),
         TRIM (fa.attribute_category_code),
         books.date_placed_in_service,
         fl.segment1,
         fl.segment2,
         fl.segment3,
         fl.segment4,
         fa.manufacturer_name,
         fa.model_number,
         fa.serial_number,
         fa.tag_number,
         ppf.full_name,
         books.life_in_months,
         books.life_in_months / 12,
         REMAINDER (books.life_in_months, 12),
         fa.owned_leased,
         REGEXP_REPLACE (fa.description, '[\|"]|([[:cntrl:]])', ' '),
         NVL (fa.attribute10, '999999'),
         ffvt.description,
         fbc.book_type_name,
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                2,
                                                SUBSTR (gcc.segment2, 1, 4)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                3,
                                                SUBSTR (gcc.segment3, 1, 5)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                4,
                                                SUBSTR (gcc.segment4, 1, 12)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                5,
                                                SUBSTR (gcc.segment5, 1, 5)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                6,
                                                SUBSTR (gcc.segment6, 1, 5)),
         gl_flexfields_pkg.get_description_sql (gcc.chart_of_accounts_id,
                                                7,
                                                SUBSTR (gcc.segment7, 1, 4)),
         fa.asset_type
                   HAVING SUM(dd_bonus.cost) <> 0;                   

--COMMENTED BY SM 23-AUG-2016                   
    /*     select         addr.asset_number                               || '|' ||
                SUBSTR(cat.asset_cost_acct, 1, 5)               || '|' ||
                SUBSTR(glcc.segment1, 1, 4)                     || '|' ||  -- Increased Company segment to 4 characters - GC
                SUBSTR(glcc.segment2, 1, 4)                     || '|' ||
                SUBSTR(glcc.segment3, 1, 5)                     || '|' ||
                SUBSTR(glcc.segment4, 1, 12)                    || '|' ||
                SUBSTR(glcc.segment5, 1, 5)                     || '|' ||
                SUBSTR(glcc.segment6, 1, 5)                     || '|' ||
                SUBSTR(glcc.segment7, 1, 4)                     || '|' ||   -- Added Intercompany segment - GC
                addr.attribute_category_code                    || '|' ||
                books.date_placed_in_service                    || '|' ||
                fal.segment1   ||'-'||  fal.segment2  ||'-'|| fal.segment3  ||'-'|| fal.segment4                                   || '|' ||
                  fal.segment1                                  || '|' ||
                 fal.segment2                                   || '|' ||
                 fal.segment3                                   || '|' ||
                 fal.segment4                                   || '|' ||
                addr.manufacturer_name                          || '|' ||
                addr.model_number                               || '|' ||
                addr.serial_number                              || '|' ||
                addr.tag_number                                 || '|' ||
                (select full_name  from per_all_people_f  where person_id = dist_hist.ASSIGNED_TO and effective_start_date <= p_from  and effective_end_date > p_to )      || '|' ||
                books.cost                                      || '|' ||
                sum(det.deprn_reserve)                          || '|' ||
           ( books.cost   -   sum(det.deprn_reserve))           || '|' ||
                books.life_in_months                            || '|' ||
                books.life_in_months/12                         || '|' ||
                remainder(books.life_in_months,12)              || '|' ||
                addr.owned_leased                               || '|' ||
                regexp_replace(addr.description,  '[\|"]|([[:cntrl:]])',' ')       || '|' || --modified rreyes to include replacement   --of pipe and nonprintable along with quote
                nvl(addr.attribute10,'999999')                  || '|' || --added rreyes cpt
                ffvt.description                                || '|' || --added rreyes cpt
                fbc.book_type_name                              || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 2,SUBSTR(glcc.segment2, 1, 4) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 3,SUBSTR(glcc.segment3, 1, 5) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 4,SUBSTR(glcc.segment4, 1, 12))                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 5,SUBSTR(glcc.segment5, 1, 5) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 6,SUBSTR(glcc.segment6, 1, 5) )                    || '|' ||
                gl_flexfields_pkg.get_description_sql(glcc.chart_of_accounts_id, 7,SUBSTR(glcc.segment7, 1, 4) )                    || '|' ||
                addr.asset_type                
                STRING
        from fa_book_controls fbc,
                fa_additions            addr     ,
                fa_asset_history        hist     ,
                fa_category_books       cat      ,
                fa_books                books    ,
                fa_distribution_history dist_hist,
                gl_code_combinations    glcc     ,
                fa_deprn_detail         det      ,
                fa_locations            fal      ,
                fnd_flex_values         ffv      ,      -- added rreyes cpt
                fnd_flex_values_tl      ffvt     ,      -- added rreyes cpt
                fnd_flex_value_sets     ffvs            -- added rreyes cpt
        where   period_counter              = (select max(period_counter)   from fa_deprn_detail where asset_id =  det.asset_id)
        and     addr.asset_id               = books.asset_id
        and     det.asset_id                = books.asset_id
        and     fbc.book_type_code(+) = books.book_type_code
        and     addr.asset_id               = hist.asset_id
        and     det.book_type_code          = cat.book_type_code --added to fix issue with multiple books since implmenting ireland sub INC0043789
        and     hist.category_id            = cat.category_id
        and     dist_hist.asset_id          = books.asset_id
        and     glcc.code_combination_id    = dist_hist.code_combination_id
        and     dist_hist.date_effective    <= p_from and nvl(dist_hist.date_ineffective, p_to) >= p_to
        and     books.date_effective        <= p_from and nvl(books.date_ineffective, p_to) >= p_to
        and     hist.date_effective         <= p_from and nvl(hist.date_ineffective, p_to) >= p_to
        and     dist_hist.location_id       = fal.location_id
        and     ffvs.flex_value_set_name    = 'REGN_CPT_PROJECT_IDS'        -- added rreyes cpt
        and     ffv.flex_value_set_id       = ffvs.flex_value_set_id        -- added rreyes cpt
        and     ffv.flex_value_id           = ffvt.flex_value_id            -- added rreyes cpt
        and     ffv.flex_value              = nvl(addr.attribute10, '999999') -- added rreyes cpt
        and     books.book_type_code        = NVL(P_BOOK,books.book_type_code)
        group by
                substr(cat.asset_cost_acct, 1, 5)  ,
                substr(glcc.segment1, 1, 4) ,    -- Increased Company segment to 4 characters - GC
                substr(glcc.segment2, 1, 4) ,
                substr(glcc.segment3, 1, 5) ,
                substr(glcc.segment4, 1, 12)  ,
                substr(glcc.segment5, 1, 5) ,
                substr(glcc.segment6, 1, 5)  ,
                substr(glcc.segment7, 1, 4)  ,  -- Added Intercompany segment - GC
                addr.asset_number               ,
                regexp_replace(addr.description, '[\|"]|([[:cntrl:]])',' '),
                addr.attribute_category_code     ,
                books.date_placed_in_service      ,
                fal.segment1, fal.segment2, fal.segment3, fal.segment4     ,
                addr.manufacturer_name ,
                addr.model_number ,
                addr.serial_number ,
                addr.tag_number   ,
                dist_hist.assigned_to,
                books.cost,
                books.life_in_months,
                addr.owned_leased,
                nvl(addr.attribute10,'999999'),
                ffvt.description,
                fbc.book_type_name,
                glcc.chart_of_accounts_id ,
                addr.asset_type
                HAVING books.cost <> 0;                   
*/
     v_line_count         NUMBER := 0;
     v_from DATE;
     v_to DATE;
     

    BEGIN
    
      fnd_file.put_line(fnd_file.log, 'p_book: '||P_book);
      fnd_file.put_line(fnd_file.log, 'P_PERIOD: '||P_PERIOD);
      fnd_file.put_line(fnd_file.log, 'p_flag: '||P_FLAG);

    
      IF P_PERIOD IS NOT NULL 
      THEN
           SELECT to_date(P_PERIOD,'MON-YY') INTO V_FROM FROM DUAL;
           SELECT to_date(P_PERIOD,'MON-YY')+1-(1/(24*60*60)) INTO V_TO FROM DUAL;
      ELSE
           V_FROM := SYSDATE;
           V_TO := SYSDATE;
      END IF;
      
      fnd_file.put_line(fnd_file.log, 'V_FROM: '||V_FROM);
      fnd_file.put_line(fnd_file.log, 'V_TO: '||V_TO);
       
      fnd_file.put_line(fnd_file.output, 'ASSET_NUMBER|ASSET_ACCOUNT|COMPANY|COST_CENTER|ACCT|PROJECT|LOCATION|FUTURE_USE|INTERCOMPANY|CATEGORY|DATE_PLACED_IN_SERVICE|LOCATION|LOCATION|CITY|BUILDING|ROOM|MANUFACTURER|MODEL|SERIAL_NUMBER|TAG_NUMBER|FULL_NAME|COST|ACCUMULATED_DEPRECIATION|NET_BOOK_VALUE|LIFE_IN_MONTHS|YEARS|MONTHS|OWNED_LEASED|DESCRIPTION|FID|FID_DESC|ASSET_BOOK_NAME|COST_CENTER_DESC|ACCT_DESC|PROJECT_DESC|LOCATION_DESC|FUTURE_USE_DESC|INTERCOMPANY_DESC|TYPE');

      BEGIN
      
      SELECT   NVL (dp.period_close_date, SYSDATE) ucd,
         dp.period_counter upc,
         MIN (dp_fy.period_open_date) tod
      INTO v_ucd,     v_upc, V_tod
      FROM     fa_deprn_periods dp, fa_deprn_periods dp_fy, fa_book_controls bc
      WHERE    dp.book_type_code = p_book
      AND      dp.period_name = P_PERIOD
      AND      dp_fy.book_type_code = p_book
      AND      dp_fy.fiscal_year = dp.fiscal_year
      AND      bc.book_type_code = p_book
      GROUP BY bc.distribution_source_book, dp.period_close_date, dp.period_counter;
      
      EXCEPTION
      WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.log, 'Unexpected Error in fetching period details: ' || SUBSTR(SQLERRM,1,300));
      END;
      
      
      
      
      IF P_FLAG ='Y' THEN
      
      FOR c_rec IN c_assets_zero_cost(P_BOOK ,V_tod , v_ucd ,v_upc) LOOP

           fnd_file.put_line(fnd_file.output, (c_rec.STRING));

          v_line_count := v_line_count + 1;

      END LOOP;
      
      ELSE 

      FOR c_rec IN c_assets_non_zero_cost(P_BOOK ,V_tod , v_ucd ,v_upc) LOOP

           fnd_file.put_line(fnd_file.output, (c_rec.STRING));

          v_line_count := v_line_count + 1;

      END LOOP;

      END IF;

      fnd_file.put_line(fnd_file.log, 'Output file contains '||v_line_count||' records');
      fnd_file.put_line(fnd_file.log, ' ');

    EXCEPTION

      WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.log, 'Unexpected Error: ' || SUBSTR(SQLERRM,1,300));

    END LIST_ASSETS ;


END REGN_ASSET_DETAILS_REPORT_PKG ;
/
