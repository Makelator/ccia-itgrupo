CREATE OR REPLACE FUNCTION public.getserial("number" character varying)
    RETURNS character varying AS
  $BODY$
  DECLARE
  number1 ALIAS FOR $1;
  res varchar;
  BEGIN
     select substring(number1,0,position('-' in number1)) into res;
     return res;  
  END;$BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100;
  ALTER FUNCTION public.getserial(character varying)
    OWNER TO odoo10;

  CREATE OR REPLACE FUNCTION public.getnumber("number" character varying)
      RETURNS character varying AS
    $BODY$
    DECLARE
    number1 ALIAS FOR $1;
    res varchar;
    BEGIN
       select substring(number1,position('-' in number1)+1) into res;
       return res;  
    END;$BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    ALTER FUNCTION public.getnumber(character varying)
      OWNER TO odoo10;


    CREATE OR REPLACE VIEW public.vst_account_currencyrate AS 
       SELECT max(account_move_line.tc) AS currency_rate,
          account_move_line.move_id,
          account_invoice.id AS invoice_id
         FROM account_move_line
           JOIN account_invoice ON account_move_line.move_id = account_invoice.move_id
        GROUP BY account_move_line.move_id, account_invoice.id;

  CREATE OR REPLACE VIEW vst_kardex_credit_final AS 
        (         SELECT DISTINCT stock_location.complete_name, 
                    product_category.name AS categoria, 
                    product_template.name as product_tmpl_id,
                    account_move.date, 
                    account_period.name AS getperiod, 
                    ''::character varying AS ctanalitica, 
                    getserial(account_invoice.reference) AS serial, 
                    getnumber(account_invoice.reference)::character varying(10) AS getnumber, 
                    ''::character varying AS operation_type, res_partner.name, 
                    0 AS ingreso, 0 AS salida, 
                        CASE
                            WHEN product_uom.id <> uomt.id THEN round((account_move_line.debit::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 2)
                            ELSE account_move_line.debit
                        END AS debit, 
                        CASE
                            WHEN product_uom.id <> uomt.id THEN round((account_move_line.credit::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 2)
                            ELSE account_move_line.credit
                        END AS credit, 
                        CASE
                            WHEN account_move_line.debit > 0::numeric THEN 'ingreso'::text
                            ELSE 'salida'::text
                        END AS esingreso, 
                    account_move_line.product_id, 
                    stock_location.id AS location_id, 
                    lpad(account_invoice.it_type_document::text, 2, '0'::text) AS doc_type_ope, 
                    account_account.id AS account_id, 
                    account_account.code AS account_invoice, 
                    einvoice_catalog_01.code::text AS type_doc, 
                    COALESCE(account_invoice.reference, ''::character varying) AS numdoc_cuadre, 
                    res_partner.nro_documento, 
                    account_invoice_line.id AS invoicelineid
                   FROM account_invoice_line
              JOIN account_invoice ON account_invoice_line.invoice_id = account_invoice.id
         JOIN product_uom ON account_invoice_line.uom_id = product_uom.id
    LEFT JOIN einvoice_catalog_01 ON account_invoice.it_type_document = einvoice_catalog_01.id
   JOIN account_move ON account_invoice.move_id = account_move.id
   JOIN account_move_line ON account_move.id = account_move_line.move_id and account_move_line.product_id = account_invoice_line.product_id
   JOIN account_account ON account_move_line.account_id = account_account.id
   JOIN res_partner ON account_invoice.partner_id = res_partner.id
   JOIN product_product ON account_move_line.product_id = product_product.id
   JOIN product_template ON product_product.product_tmpl_id = product_template.id
   JOIN product_uom uomt ON product_template.uom_id = uomt.id
   JOIN product_category ON product_template.categ_id = product_category.id
   JOIN stock_location ON account_invoice_line.location_id = stock_location.id
   JOIN account_period ON account_period.date_start <= account_move.date and account_period.date_stop >= account_move.date  and account_period.special = account_move.fecha_special
   JOIN account_journal ON account_move_line.journal_id = account_journal.id
   LEFT JOIN stock_picking sp ON sp.invoice_id = account_invoice.id
   LEFT JOIN stock_move sm ON sm.picking_id = sp.id AND sm.product_id = product_product.id
   LEFT JOIN account_analytic_tag_account_invoice_line_rel ON account_analytic_tag_account_invoice_line_rel.account_invoice_line_id = account_invoice_line.id
   --WHERE account_account.code like (select prefijo from main_parameter)
   --WHERE strpos(account_account.code, (select prefijo from main_parameter)) = 1
   WHERE account_analytic_tag_account_invoice_line_rel.account_analytic_tag_id IN (SELECT account_analytic_tag_id FROM account_analytic_tag_account_invoice_line_rel)

        UNION ALL 
                 SELECT DISTINCT stock_location.complete_name, 
                    product_category.name AS categoria, 
                    product_template.name as product_tmpl_id, 
                    account_move.date, 
                    account_period.name AS getperiod, 
                    ''::character varying AS ctanalitica, 
                    getserial(account_invoice.reference) AS serial, 
                    getnumber(account_invoice.reference)::character varying(10) AS getnumber, 
                    ''::character varying AS operation_type, res_partner.name, 
                    0 AS ingreso, 
                        CASE
                            WHEN product_uom.id <> uomt.id THEN round((sm.product_uom_qty::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 6)
                            ELSE sm.product_uom_qty
                        END AS salida, 
                    0 AS debit, 
                        CASE
                            WHEN product_uom.id <> uomt.id THEN (round((sm.product_uom_qty::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 6) * round((sm.price_unit::double precision * product_uom.factor::double precision / uomt.factor::double precision)::numeric, 6))::double precision
                            ELSE sm.price_unit::double precision * sm.product_uom_qty::double precision
                        END AS credit, 
                    'ingreso'::text AS esingreso, account_move_line.product_id, 
                    stock_location.id AS location_id, 
                    lpad(account_invoice.it_type_document::text, 2, '0'::text) AS doc_type_ope, 
                    account_account.id AS account_id, 
                    account_account.code AS account_invoice, 
                    einvoice_catalog_01.code::text AS type_doc, 
                    COALESCE(account_invoice.reference, ''::character varying) AS numdoc_cuadre, 
                    res_partner.nro_documento, 0 AS invoicelineid
                   FROM account_invoice_line
              JOIN account_invoice ON account_invoice_line.invoice_id = account_invoice.id
         JOIN product_uom ON account_invoice_line.uom_id = product_uom.id
    LEFT JOIN einvoice_catalog_01 ON account_invoice.it_type_document = einvoice_catalog_01.id
   JOIN account_move ON account_invoice.move_id = account_move.id
   JOIN account_move_line ON account_move.id = account_move_line.move_id and account_move_line.product_id = account_invoice_line.product_id
   JOIN account_account ON account_move_line.account_id = account_account.id
   JOIN res_partner ON account_invoice.partner_id = res_partner.id
   JOIN product_product ON account_move_line.product_id = product_product.id
   JOIN product_template ON product_product.product_tmpl_id = product_template.id
   JOIN product_category ON product_template.categ_id = product_category.id
   JOIN product_uom uomt ON uomt.id = 
CASE
WHEN product_template.unidad_kardex IS NOT NULL THEN product_template.unidad_kardex
ELSE product_template.uom_id
END
   JOIN account_period ON account_period.date_start <= account_move.date and account_period.date_stop >= account_move.date  and account_period.special = account_move.fecha_special
   JOIN account_journal ON account_move_line.journal_id = account_journal.id
   JOIN stock_picking sp ON sp.invoice_id = account_invoice.id
   JOIN stock_move sm ON sm.picking_id = sp.id AND sm.product_id = product_product.id
   LEFT JOIN stock_location ON account_invoice_line.location_id = stock_location.id
   LEFT JOIN account_analytic_tag_account_invoice_line_rel ON account_analytic_tag_account_invoice_line_rel.account_invoice_line_id = account_invoice_line.id
   --WHERE account_invoice.is_fixer <> true AND account_invoice.type::text = 'in_refund'::text)
   --WHERE account_account.code like (select prefijo from main_parameter) AND account_invoice.type::text = 'in_refund'::text)
   --WHERE strpos(account_account.code, (select prefijo from main_parameter)) = 0 AND account_invoice.type::text = 'in_refund'::text)
   WHERE  (account_analytic_tag_account_invoice_line_rel.account_analytic_tag_id IS  NULL
   OR account_analytic_tag_account_invoice_line_rel.account_analytic_tag_id NOT IN (SELECT account_analytic_tag_id FROM account_analytic_tag_account_invoice_line_rel))
   AND account_invoice.type::text = 'in_refund'::text
   )
UNION ALL 
         SELECT DISTINCT stock_location.complete_name, 
            product_category.name AS categoria, product_template.name AS product_tmpl_id, 
            account_move.date, account_period.name AS getperiod, 
            ''::character varying AS ctanalitica, 
            getserial(account_invoice.reference) AS serial, 
            getnumber(account_invoice.reference)::character varying(10) AS getnumber, 
            ''::character varying AS operation_type, res_partner.name, 
                CASE
                    WHEN product_uom.id <> uomt.id THEN round((sm.product_uom_qty::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 6)
                    ELSE sm.product_uom_qty
                END AS ingreso, 
            0 AS salida, 
                CASE
                    WHEN product_uom.id <> uomt.id THEN (round((sm.product_uom_qty::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 6) * round((sm.price_unit::double precision * product_uom.factor::double precision / uomt.factor::double precision)::numeric, 6))::double precision
                    ELSE sm.price_unit::double precision * sm.product_uom_qty::double precision
                END AS debit, 
            0 AS credit, 'salida'::text AS esingreso, 
            account_move_line.product_id, stock_location.id AS location_id, 
            lpad(account_invoice.it_type_document::text, 2, '0'::text) AS doc_type_ope, 
            account_account.id AS account_id, 
            account_account.code AS account_invoice, 
            einvoice_catalog_01.code::text AS type_doc, 
            COALESCE(account_invoice.reference, ''::character varying) AS numdoc_cuadre, 
            res_partner.nro_documento, 0 AS invoicelineid
           FROM account_invoice_line
      JOIN account_invoice ON account_invoice_line.invoice_id = account_invoice.id
   JOIN product_uom ON account_invoice_line.uom_id = product_uom.id
   LEFT JOIN einvoice_catalog_01 ON account_invoice.it_type_document = einvoice_catalog_01.id
   JOIN account_move ON account_invoice.move_id = account_move.id
   JOIN account_move_line ON account_move.id = account_move_line.move_id and account_move_line.product_id = account_invoice_line.product_id
   JOIN account_account ON account_move_line.account_id = account_account.id
   JOIN res_partner ON account_invoice.partner_id = res_partner.id
   JOIN product_product ON account_move_line.product_id = product_product.id
   JOIN product_template ON product_product.product_tmpl_id = product_template.id
   JOIN product_category ON product_template.categ_id = product_category.id
   JOIN product_uom uomt ON uomt.id = 
CASE
WHEN product_template.unidad_kardex IS NOT NULL THEN product_template.unidad_kardex
ELSE product_template.uom_id
END
   JOIN account_period ON account_period.date_start <= account_move.date and account_period.date_stop >= account_move.date  and account_period.special = account_move.fecha_special
   JOIN account_journal ON account_move_line.journal_id = account_journal.id
   JOIN stock_picking sp ON sp.invoice_id = account_invoice.id
   JOIN stock_move sm ON sm.picking_id = sp.id AND sm.product_id = product_product.id
   LEFT JOIN stock_location ON account_invoice_line.location_id = stock_location.id
   LEFT JOIN account_analytic_tag_account_invoice_line_rel ON account_analytic_tag_account_invoice_line_rel.account_invoice_line_id = account_invoice_line.id
   --WHERE account_invoice.is_fixer <> true AND account_invoice.type::text = 'in_invoice'::text;
  --WHERE account_account.code like (select prefijo from main_parameter) AND account_invoice.type::text = 'in_refund'::text;
  --WHERE strpos(account_account.code, (select prefijo from main_parameter)) = 0 AND account_invoice.type::text = 'in_invoice'::text;
   WHERE  (account_analytic_tag_account_invoice_line_rel.account_analytic_tag_id IS  NULL
   OR account_analytic_tag_account_invoice_line_rel.account_analytic_tag_id NOT IN (SELECT account_analytic_tag_id FROM account_analytic_tag_account_invoice_line_rel))
   AND account_invoice.type::text = 'in_invoice'::text;
ALTER TABLE vst_kardex_credit_final
  OWNER TO odoo10;




CREATE OR REPLACE VIEW public.vst_stock_move_final AS 
 SELECT stock_move.product_uom,
    stock_move.move_dest_id,
        CASE
            WHEN sl.usage::text = 'supplier'::text THEN 0::double precision
            ELSE
            CASE
                WHEN stock_picking_type.code::text = 'internal'::text THEN
                CASE
                    WHEN product_uom.id <> uomt.id THEN round((stock_move.precio_unitario_manual * product_uom.factor::double precision / uomt.factor::double precision)::numeric, 6)::double precision
                    ELSE stock_move.precio_unitario_manual
                END
                ELSE
                CASE
                    WHEN product_uom.id <> uomt.id THEN round((stock_move.price_unit::double precision * product_uom.factor::double precision / uomt.factor::double precision)::numeric, 6)::double precision
                    ELSE stock_move.price_unit::double precision
                END
            END
        END AS price_unit,
        CASE
            WHEN product_uom.id <> uomt.id THEN round((stock_move.product_uom_qty::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 6)
            ELSE stock_move.product_uom_qty
        END AS product_uom_qty,
        CASE
            WHEN product_uom.id <> uomt.id THEN round((stock_move.product_uom_qty::double precision * uomt.factor::double precision / product_uom.factor::double precision)::numeric, 6)
            ELSE stock_move.product_uom_qty
        END AS product_qty,
    stock_move.location_id,
    stock_move.picking_type_id,
    stock_move.state,
    stock_move.product_id,
    stock_move.picking_id,
    stock_move.location_dest_id,
    COALESCE(stock_picking.invoice_id, 0) AS invoice_id,
        CASE
            WHEN stock_picking.es_fecha_kardex THEN stock_picking.fecha_kardex
            ELSE
            CASE
                WHEN ai.date_invoice IS NULL THEN stock_picking.date
                ELSE ai.date_invoice::timestamp without time zone
            END
        END AS date,
    stock_picking.name,
    stock_picking.partner_id,
    einvoice_catalog_12.code as guia,
    stock_move.analitic_id,
    stock_move.id,
    product_product.default_code,
        CASE
            WHEN stock_move.raw_material_production_id IS NOT NULL THEN mrp1.name
            ELSE
            CASE
                WHEN stock_move.production_id IS NOT NULL THEN mrp2.name
                ELSE ''::character varying
            END
        END AS mrpname
   FROM stock_move
     
     JOIN product_uom ON stock_move.product_uom = product_uom.id
     JOIN stock_picking ON stock_move.picking_id = stock_picking.id
     JOIN stock_picking_type ON stock_picking.picking_type_id = stock_picking_type.id
     JOIN stock_location sl ON sl.id = stock_move.location_id
     JOIN product_product ON stock_move.product_id = product_product.id
     JOIN product_template ON product_product.product_tmpl_id = product_template.id
     JOIN einvoice_catalog_12 ON stock_picking.einvoice_12 = einvoice_catalog_12.id
     JOIN product_uom uomt ON uomt.id =
        CASE
            WHEN product_template.unidad_kardex IS NOT NULL THEN product_template.unidad_kardex
            ELSE product_template.uom_id
        END
     LEFT JOIN mrp_production mrp1 ON stock_move.raw_material_production_id = mrp1.id
     LEFT JOIN mrp_production mrp2 ON stock_move.production_id = mrp2.id
     LEFT JOIN account_invoice ai ON ai.id = stock_picking.invoice_id
  WHERE stock_move.state::text = 'done'::text AND product_template.type::text = 'product'::text AND stock_move.picking_id IS NOT NULL;

ALTER TABLE public.vst_stock_move_final
  OWNER TO odoo10;




  CREATE OR REPLACE FUNCTION public.getperiod(
    move_id integer,
    date_picking date,
    special boolean)
  RETURNS character varying AS
$BODY$
DECLARE
move_id1 ALIAS FOR $1;
date_picking1 ALIAS FOR $2;
res varchar;
isspecial alias for special;
BEGIN
    IF move_id1 !=0 THEN
  select account_period.name into res from account_move 
  inner join account_period on account_period.date_start <= account_move.date and account_period.date_stop >= account_move.date  and account_period.special = account_move.fecha_specia
  where account_move.id=move_id1;
    ELSE 
  select account_period.name into res from account_period
  where date_start<=date_picking1 and date_stop>=date_picking1 and account_period.special=isspecial;
   END IF;
   return res;  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.getperiod(integer, date, boolean)
  OWNER TO odoo10;



  CREATE OR REPLACE FUNCTION public.getperiod(
    date_picking timestamp without time zone,
    special boolean)
  RETURNS character varying AS
$BODY$
DECLARE
date_picking1 ALIAS FOR $1;
res varchar;
isspecial alias for $2;
BEGIN
  select account_period.name into res from account_period
  where date_start<=date_picking1 and date_stop>=date_picking1 and account_period.special=isspecial;
   return res;  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.getperiod(timestamp without time zone, boolean)
  OWNER TO odoo10;



CREATE OR REPLACE VIEW public.vst_invoice_line_final AS 
 SELECT sum(account_move_line.debit) / sum(
        CASE
            WHEN account_move_line.quantity IS NULL OR account_move_line.quantity = 0::numeric THEN 1::numeric
            ELSE account_move_line.quantity
        END) AS price_unit,
    account_move_line.product_id,
    account_invoice.id AS invoice_id,
    max(account_move_line.account_id) AS account_id
   FROM account_move_line
     JOIN account_move ON account_move_line.move_id = account_move.id
     JOIN account_invoice ON account_move.id = account_invoice.move_id
     JOIN product_product pp ON pp.id = account_move_line.product_id
     JOIN product_template pt ON pt.id = pp.product_tmpl_id
  WHERE account_move_line.quantity IS NOT NULL AND account_move_line.product_id IS NOT NULL AND pt.type::text = 'product'::text AND account_move_line.debit <> 0::numeric
  GROUP BY account_move_line.product_id, account_invoice.id
  ORDER BY account_invoice.id, account_move_line.product_id;

ALTER TABLE public.vst_invoice_line_final
  OWNER TO odoo10;




  CREATE OR REPLACE VIEW public.vst_kardex_fis_1_final AS 
 SELECT k.origen,
    k.destino,
    k.serial,
    k.nro,
    k.cantidad,
    k.ingreso,
    k.producto,
    k.fecha,
    k.id_origen,
    k.id_destino,
    k.product_id,
    k.id,
    k.categoria,
    k.name,
    k.unidad,
    k.default_code,
    k.cadquiere,
    k.currency_rate,
    k.price_unit,
    k.invoice_id,
    k.periodo,
    k.ctanalitica,
    k.operation_type,
    k.doc_type_ope,
    k.account_invoice,
    k.category_id,
    (aa_cp.code::text || ' - '::text) || aa_cp.name::text AS product_account,
    k.id_origen AS ubicacion_origen,
    k.id_destino AS ubicacion_destino,
    k.id AS stock_moveid,
    k.mrpname,
    k.stock_doc,
    k.price_stock_move,
    k.type_doc,
    k.numdoc_cuadre,
    k.nro_documento AS doc_partner
   FROM ( SELECT origen.complete_name AS origen,
            destino.complete_name AS destino,
            getserial(account_invoice.reference) AS serial,
                CASE
                    WHEN vst_stock_move.invoice_id <> 0 THEN getnumber(account_invoice.reference)::character varying(10)
                    ELSE vst_stock_move.name
                END AS nro,
            vst_stock_move.product_qty AS cantidad,
            vst_stock_move.product_qty AS ingreso,
            product_template.name AS producto,
            vst_stock_move.date AS fecha,
            vst_stock_move.location_id AS id_origen,
            vst_stock_move.location_dest_id AS id_destino,
            vst_stock_move.product_id,
            vst_stock_move.id,
            product_category.name AS categoria,
                CASE
                    WHEN vst_stock_move.invoice_id = 0 THEN res_partner.name
                    ELSE rp.name
                END AS name,
            uomt.name AS unidad,
            product_product.default_code,
                CASE
                    WHEN vst_stock_move.price_unit = 0::double precision THEN COALESCE(vst_invoice_line.price_unit, 0::numeric)::double precision
                    ELSE vst_stock_move.price_unit
                END AS cadquiere,
            vst_account_currencyrate.currency_rate,
                CASE
                    WHEN vst_stock_move.price_unit = 0::double precision THEN COALESCE(vst_invoice_line.price_unit, 0::numeric)::double precision
                    ELSE vst_stock_move.price_unit
                END AS price_unit,
            vst_stock_move.invoice_id,
                CASE
                    WHEN vst_stock_move.invoice_id <> 0 THEN account_period.name
                    ELSE getperiod(vst_stock_move.date::date::timestamp without time zone, true)
                END AS periodo,
            account_analytic_account.name AS ctanalitica,
            lpad(vst_stock_move.guia::text, 2, '0'::text)::character varying AS operation_type,
            lpad(it_type_document.code::text, 2, '0'::text) AS doc_type_ope,
                CASE
                    WHEN vst_stock_move.invoice_id <> 0 THEN (aa_invoice_m.code::text || ' - '::text) || aa_invoice_m.name::text
                    ELSE ''::text
                END AS account_invoice,
            product_category.id AS category_id,
            vst_stock_move.mrpname,
            vst_stock_move.name AS stock_doc,
            COALESCE(vst_stock_move.price_unit, 0::numeric::double precision) AS price_stock_move,
            it_type_document.code AS type_doc,
            COALESCE(account_invoice.reference, ''::character varying) AS numdoc_cuadre,
            res_partner.nro_documento
           FROM vst_stock_move_final vst_stock_move
             JOIN product_product ON vst_stock_move.product_id = product_product.id
             JOIN product_template ON product_product.product_tmpl_id = product_template.id
             JOIN product_category ON product_template.categ_id = product_category.id
             JOIN product_uom ON vst_stock_move.product_uom = product_uom.id
             JOIN product_uom uomt ON product_template.uom_id = uomt.id
             LEFT JOIN vst_invoice_line_final vst_invoice_line ON vst_stock_move.invoice_id = vst_invoice_line.invoice_id AND vst_stock_move.product_id = vst_invoice_line.product_id
             LEFT JOIN account_invoice ON vst_stock_move.invoice_id = account_invoice.id
             LEFT JOIN account_move ON account_invoice.move_id = account_move.id
             LEFT JOIN account_analytic_account ON vst_stock_move.analitic_id = account_analytic_account.id
             JOIN stock_location origen ON vst_stock_move.location_id = origen.id
             JOIN stock_location destino ON vst_stock_move.location_dest_id = destino.id
             LEFT JOIN res_partner ON vst_stock_move.partner_id = res_partner.id
             LEFT JOIN res_partner rp ON account_invoice.partner_id = rp.id
             LEFT JOIN vst_account_currencyrate ON vst_stock_move.id = vst_account_currencyrate.move_id
             LEFT JOIN account_period ON account_period.date_start <= account_move.date and account_period.date_stop >= account_move.date  and account_period.special = account_move.fecha_special
             LEFT JOIN einvoice_catalog_01 it_type_document ON account_invoice.it_type_document = it_type_document.id
             LEFT JOIN account_account aa_invoice_m ON vst_invoice_line.account_id = aa_invoice_m.id
             LEFT JOIN ir_property ipx ON ipx.res_id::text = ('product.template,'::text || product_template.id) AND ipx.name::text = 'cost_method'::text) k
     LEFT JOIN ( SELECT "substring"(ir_property.res_id::text, "position"(ir_property.res_id::text, ','::text) + 1)::integer AS categ_id,
            "substring"(ir_property.value_reference::text, "position"(ir_property.value_reference::text, ','::text) + 1)::integer AS account_id
           FROM ir_property
          WHERE ir_property.name::text = 'property_stock_valuation_account_id'::text) j ON k.category_id = j.categ_id
     LEFT JOIN account_account aa_cp ON j.account_id = aa_cp.id;

ALTER TABLE public.vst_kardex_fis_1_final
  OWNER TO odoo10;


  CREATE OR REPLACE VIEW public.vst_kardex_fis_1_1_final AS 
 SELECT vst_kardex_fis_1.id,
    vst_kardex_fis_1.origen,
    vst_kardex_fis_1.destino,
    vst_kardex_fis_1.serial,
    vst_kardex_fis_1.nro,
    vst_kardex_fis_1.cantidad AS ingreso,
    0::numeric AS salida,
    0::numeric AS saldof,
    vst_kardex_fis_1.producto,
    vst_kardex_fis_1.fecha,
    vst_kardex_fis_1.id_origen,
    vst_kardex_fis_1.id_destino,
    vst_kardex_fis_1.product_id,
    vst_kardex_fis_1.id_destino AS location_id,
    vst_kardex_fis_1.destino AS almacen,
    vst_kardex_fis_1.categoria,
    vst_kardex_fis_1.name,
    'in'::text AS type,
    'ingreso'::text AS esingreso,
    vst_kardex_fis_1.default_code,
    vst_kardex_fis_1.unidad,
        CASE
            WHEN ipx.value_text = 'specific'::text THEN vst_kardex_fis_1.price_unit
            ELSE
            CASE
                WHEN btrim(vst_kardex_fis_1.type_doc::text) = '07'::text THEN vst_kardex_fis_1.price_stock_move * vst_kardex_fis_1.cantidad::double precision
                ELSE vst_kardex_fis_1.price_unit * vst_kardex_fis_1.cantidad::double precision
            END
        END AS debit,
    0::numeric AS credit,
    0::numeric AS saldov,
        CASE
            WHEN btrim(vst_kardex_fis_1.type_doc::text) = '07'::text THEN vst_kardex_fis_1.price_stock_move
            ELSE vst_kardex_fis_1.cadquiere
        END AS cadquiere,
    0::numeric AS cprom,
    vst_kardex_fis_1.periodo,
    vst_kardex_fis_1.ctanalitica,
    vst_kardex_fis_1.operation_type,
    vst_kardex_fis_1.doc_type_ope,
    vst_kardex_fis_1.account_invoice,
    vst_kardex_fis_1.product_account,
    vst_kardex_fis_1.ubicacion_origen,
    vst_kardex_fis_1.ubicacion_destino,
    vst_kardex_fis_1.stock_moveid,
    vst_kardex_fis_1.mrpname,
    vst_kardex_fis_1.stock_doc,
    vst_kardex_fis_1.type_doc,
    vst_kardex_fis_1.numdoc_cuadre,
    vst_kardex_fis_1.doc_partner
   FROM vst_kardex_fis_1_final vst_kardex_fis_1
     JOIN stock_location ON vst_kardex_fis_1.id_destino = stock_location.id
     JOIN product_product pp ON pp.id = vst_kardex_fis_1.product_id
     JOIN product_template pt ON pt.id = pp.product_tmpl_id
     LEFT JOIN ir_property ipx ON ipx.res_id::text = ('product.template,'::text || pt.id) AND ipx.name::text = 'cost_method'::text
  WHERE stock_location.usage::text = 'internal'::text
UNION ALL
 SELECT vst_kardex_fis_1.id,
    vst_kardex_fis_1.origen,
    vst_kardex_fis_1.destino,
    vst_kardex_fis_1.serial,
    vst_kardex_fis_1.nro,
    0::numeric AS ingreso,
    vst_kardex_fis_1.cantidad AS salida,
    0::numeric AS saldof,
    vst_kardex_fis_1.producto,
    vst_kardex_fis_1.fecha,
    vst_kardex_fis_1.id_origen,
    vst_kardex_fis_1.id_destino,
    vst_kardex_fis_1.product_id,
    vst_kardex_fis_1.id_origen AS location_id,
    vst_kardex_fis_1.origen AS almacen,
    vst_kardex_fis_1.categoria,
    vst_kardex_fis_1.name,
    'out'::text AS type,
    'salida'::text AS esingreso,
    vst_kardex_fis_1.default_code,
    vst_kardex_fis_1.unidad,
    0::numeric AS debit,
    0::numeric AS credit,
    0::numeric AS saldov,
    0::numeric AS cadquiere,
    0::numeric AS cprom,
    vst_kardex_fis_1.periodo,
    vst_kardex_fis_1.ctanalitica,
    vst_kardex_fis_1.operation_type,
    vst_kardex_fis_1.doc_type_ope,
    vst_kardex_fis_1.account_invoice,
    vst_kardex_fis_1.product_account,
    vst_kardex_fis_1.ubicacion_origen,
    vst_kardex_fis_1.ubicacion_destino,
    vst_kardex_fis_1.stock_moveid,
    vst_kardex_fis_1.mrpname,
    vst_kardex_fis_1.stock_doc,
    vst_kardex_fis_1.type_doc,
    vst_kardex_fis_1.numdoc_cuadre,
    vst_kardex_fis_1.doc_partner
   FROM vst_kardex_fis_1_final vst_kardex_fis_1
     JOIN stock_location ON vst_kardex_fis_1.id_origen = stock_location.id
  WHERE stock_location.usage::text = 'internal'::text;

ALTER TABLE public.vst_kardex_fis_1_1_final
  OWNER TO odoo10;




  CREATE OR REPLACE VIEW public.vst_kardex_sunat_final AS 
 SELECT t.almacen,
    t.categoria,
    t.producto,
    t.fecha,
    t.periodo,
    t.ctanalitica,
    t.serial,
    t.nro,
    t.operation_type,
    t.name,
    t.ingreso,
    t.salida,
    0::numeric AS saldof,
    t.debit::numeric AS debit,
    t.credit,
    t.cadquiere::numeric AS cadquiere,
    0::numeric AS saldov,
    0::numeric AS cprom,
    t.type::character varying AS type,
    t.esingreso,
    t.product_id,
    t.location_id,
    t.doc_type_ope,
    t.ubicacion_origen,
    t.ubicacion_destino,
    t.stock_moveid,
    t.product_account,
    t.account_invoice,
    t.default_code,
    t.unidad,
    t.mrpname,
    t.stock_doc,
    t.origen,
    t.destino,
    t.type_doc,
    t.numdoc_cuadre,
    t.doc_partner,
    t.invoicelineid
   FROM ( SELECT vst_kardex_fis_1_1.almacen,
            vst_kardex_fis_1_1.categoria,
            vst_kardex_fis_1_1.producto,
            vst_kardex_fis_1_1.fecha::date AS fecha,
            vst_kardex_fis_1_1.periodo,
            vst_kardex_fis_1_1.ctanalitica,
            vst_kardex_fis_1_1.serial,
            vst_kardex_fis_1_1.nro,
            vst_kardex_fis_1_1.operation_type,
            vst_kardex_fis_1_1.name,
            vst_kardex_fis_1_1.ingreso,
            vst_kardex_fis_1_1.salida,
            vst_kardex_fis_1_1.debit,
            vst_kardex_fis_1_1.credit,
            vst_kardex_fis_1_1.type,
            vst_kardex_fis_1_1.esingreso,
            vst_kardex_fis_1_1.product_id,
            vst_kardex_fis_1_1.location_id,
            vst_kardex_fis_1_1.cadquiere,
            vst_kardex_fis_1_1.doc_type_ope::character varying AS doc_type_ope,
            vst_kardex_fis_1_1.ubicacion_origen,
            vst_kardex_fis_1_1.ubicacion_destino,
            vst_kardex_fis_1_1.stock_moveid,
            vst_kardex_fis_1_1.product_account,
            vst_kardex_fis_1_1.account_invoice,
            vst_kardex_fis_1_1.default_code,
            vst_kardex_fis_1_1.unidad,
            vst_kardex_fis_1_1.mrpname,
            vst_kardex_fis_1_1.stock_doc,
            vst_kardex_fis_1_1.origen,
            vst_kardex_fis_1_1.destino,
            vst_kardex_fis_1_1.type_doc,
            vst_kardex_fis_1_1.numdoc_cuadre,
            vst_kardex_fis_1_1.doc_partner,
            0 AS invoicelineid
           FROM vst_kardex_fis_1_1_final vst_kardex_fis_1_1
        UNION ALL
         SELECT vst_kardex_debitcredit_note.complete_name,
            vst_kardex_debitcredit_note.categoria,
            vst_kardex_debitcredit_note.product_tmpl_id AS producto,
            vst_kardex_debitcredit_note.date AS fecha,
            vst_kardex_debitcredit_note.getperiod,
            vst_kardex_debitcredit_note.ctanalitica,
            vst_kardex_debitcredit_note.serial,
            vst_kardex_debitcredit_note.getnumber,
            vst_kardex_debitcredit_note.operation_type,
            vst_kardex_debitcredit_note.name,
            vst_kardex_debitcredit_note.ingreso,
            vst_kardex_debitcredit_note.salida,
            vst_kardex_debitcredit_note.debit,
            vst_kardex_debitcredit_note.credit,
            ''::text AS type,
            vst_kardex_debitcredit_note.esingreso,
            vst_kardex_debitcredit_note.product_id,
            vst_kardex_debitcredit_note.location_id,
            0::numeric AS cadquiere,
            vst_kardex_debitcredit_note.doc_type_ope::character varying AS doc_type_ope,
            0 AS ubicacion_origen,
            0 AS ubicacion_destino,
            0 AS stock_moveid,
            (aa_cp.code::text || ' - '::text) || aa_cp.name::text AS product_account,
            vst_kardex_debitcredit_note.account_invoice,
            ''::text AS default_code,
            ''::text AS unidad,
            ''::text AS mrpname,
            ''::text AS stock_doc,
            ''::text AS origen,
            ''::text AS destino,
            vst_kardex_debitcredit_note.type_doc::character varying(2) AS type_doc,
            vst_kardex_debitcredit_note.numdoc_cuadre,
            vst_kardex_debitcredit_note.nro_documento AS doc_partner,
            vst_kardex_debitcredit_note.invoicelineid
           FROM vst_kardex_credit_final vst_kardex_debitcredit_note
             JOIN product_product ON vst_kardex_debitcredit_note.product_id = product_product.id
             JOIN product_template ON product_product.product_tmpl_id = product_template.id
             JOIN product_category ON product_template.categ_id = product_category.id
             LEFT JOIN ( SELECT "substring"(ir_property.res_id::text, "position"(ir_property.res_id::text, ','::text) + 1)::integer AS categ_id,
                    "substring"(ir_property.value_reference::text, "position"(ir_property.value_reference::text, ','::text) + 1)::integer AS account_id
                   FROM ir_property
                  WHERE ir_property.name::text = 'property_stock_valuation_account_id'::text) j ON product_category.id = j.categ_id
             LEFT JOIN account_account aa_cp ON j.account_id = aa_cp.id) t
  ORDER BY t.almacen, t.producto, t.periodo, t.fecha, t.esingreso;



CREATE OR REPLACE FUNCTION get_kardex_v(IN date_ini integer, IN date_end integer, IN productos integer[], IN almacenes integer[], OUT almacen character varying, OUT categoria character varying, OUT name_template character varying, OUT fecha date, OUT periodo character varying, OUT ctanalitica character varying, OUT serial character varying, OUT nro character varying, OUT operation_type character varying, OUT name character varying, OUT ingreso numeric, OUT salida numeric, OUT saldof numeric, OUT debit numeric, OUT credit numeric, OUT cadquiere numeric, OUT saldov numeric, OUT cprom numeric, OUT type character varying, OUT esingreso text, OUT product_id integer, OUT location_id integer, OUT doc_type_ope character varying, OUT ubicacion_origen integer, OUT ubicacion_destino integer, OUT stock_moveid integer, OUT account_invoice character varying, OUT product_account character varying, OUT default_code character varying, OUT unidad character varying, OUT mrpname character varying, OUT ruc character varying, OUT comapnyname character varying, OUT cod_sunat character varying, OUT tipoprod character varying, OUT coduni character varying, OUT metodo character varying, OUT cu_entrada numeric, OUT cu_salida numeric, OUT period_name character varying, OUT stock_doc character varying, OUT origen character varying, OUT destino character varying, OUT type_doc character varying, OUT numdoc_cuadre character varying, OUT doc_partner character varying, OUT fecha_albaran date, OUT pedido_compra character varying, OUT licitacion character varying, OUT doc_almac character varying, OUT lote character varying)
  RETURNS SETOF record AS
$BODY$  
DECLARE 
  location integer;
  product integer;
  precprom numeric;
  h record;
  h1 record;
  h2 record;
  dr record;
  pt record;
  il record;
  loc_id integer;
  prod_id integer;
  contador integer;
  lote_idmp varchar;
  
BEGIN

  select res_partner.name,res_partner.nro_documento from res_company 
  inner join res_partner on res_company.partner_id = res_partner.id
  into h;

  -- foreach product in array $3 loop
    
            loc_id = -1;
            prod_id = -1;
            lote_idmp = -1;
--    foreach location in array $4  loop
--      for dr in cursor_final loop
      saldof =0;
      saldov =0;
      cprom =0;
      cadquiere =0;
      ingreso =0;
      salida =0;
      debit =0;
      credit =0;
           contador = 2;
      
      
      for dr in 
      select *,sp.name as doc_almac,sp.date::date as fecha_albaran, po.name as pedido_compra, pr.name as licitacion,spl.name as lote,
      ''::character varying as ruc,''::character varying as comapnyname, ''::character varying as cod_sunat,''::character varying as default_code,ipx.value_text as ipxvalue,
      ''::character varying as tipoprod ,''::character varying as coduni ,''::character varying as metodo, 0::numeric as cu_entrada , 0::numeric as cu_salida, ''::character varying as period_name  
      from vst_kardex_sunat_final as vst_kardex_sunat
left join stock_move sm on sm.id = vst_kardex_sunat.stock_moveid
left join stock_production_lot spl on spl.id = sm.restrict_lot_id
left join stock_picking sp on sp.id = sm.picking_id
left join purchase_order po on po.id = sp.po_id
left join purchase_requisition pr on pr.id = po.requisition_id
left join account_invoice_line ail on ail.id = vst_kardex_sunat.invoicelineid
left join product_product pp on pp.id = vst_kardex_sunat.product_id
left join product_template ptp on ptp.id = pp.product_tmpl_id
LEFT JOIN ir_property ipx ON ipx.res_id::text = ('product.template,'::text || ptp.id) AND ipx.name::text = 'cost_method'::text 
          
       where fecha_num(vst_kardex_sunat.fecha::date) between $1 and $2  
      order by vst_kardex_sunat.location_id,vst_kardex_sunat.product_id,vst_kardex_sunat.fecha,vst_kardex_sunat.esingreso,vst_kardex_sunat.nro
        loop
        if dr.location_id = ANY ($4) and dr.product_id = ANY ($3) then
          if dr.ipxvalue = 'specific' then
                    if loc_id = dr.location_id then
              contador = 1;
              else
              
              loc_id = dr.location_id;
              prod_id = dr.product_id;
          --    foreach location in array $4  loop
              
          --      for dr in cursor_final loop
              saldof =0;
              saldov =0;
              cprom =0;
              cadquiere =0;
              ingreso =0;
              salida =0;
              debit =0;
              credit =0;
            end if;
              else
            

                if prod_id = dr.product_id and loc_id = dr.location_id then
                contador =1;
                else

              loc_id = dr.location_id;
              prod_id = dr.product_id;
          --    foreach location in array $4  loop
          --      for dr in cursor_final loop
                saldof =0;
                saldov =0;
                cprom =0;
                cadquiere =0;
                ingreso =0;
                salida =0;
                debit =0;
                credit =0;
                end if;
           end if;

            select '' as category_sunat_code, '' as uom_sunat_code
            from product_product
            inner join product_template on product_product.product_tmpl_id = product_template.id
            inner join product_category on product_template.categ_id = product_category.id
            inner join product_uom on product_template.uom_id = product_uom.id
            --left join category_product_sunat on product_category.cod_sunat = category_product_sunat.id
            --left join category_uom_sunat on product_uom.cod_sunat = category_uom_sunat.id
            where product_product.id = dr.product_id into h1;

                              select * from stock_location where id = dr.location_id into h2;
        
          ---- esto es para las variables que estan en el crusor y pasarlas a las variables output
          
          almacen=dr.almacen;
          categoria=dr.categoria;
          name_template=dr.producto;
          fecha=dr.fecha;
          periodo=dr.periodo;
          ctanalitica=dr.ctanalitica;
          serial=dr.serial;
          nro=dr.nro;
          operation_type=dr.operation_type;
          name=dr.name;
          type=dr.type;
          esingreso=dr.esingreso;
          product_id=dr.product_id;

          location_id=dr.location_id;
          doc_type_ope=dr.doc_type_ope;
          ubicacion_origen=dr.ubicacion_origen;
          ubicacion_destino=dr.ubicacion_destino;
          stock_moveid=dr.stock_moveid;
          account_invoice=dr.account_invoice;
          product_account=dr.product_account;
          default_code=dr.default_code;
          unidad=dr.unidad;
          mrpname=dr.mrpname;
          stock_doc=dr.stock_doc;
          origen=dr.origen;
          destino=dr.destino;
          type_doc=dr.type_doc;
                numdoc_cuadre=dr.numdoc_cuadre;
                doc_partner=dr.doc_partner;
                lote= dr.lote;


        

           ruc = h.nro_documento;
           comapnyname = h.name;
           cod_sunat = ''; 
           default_code = dr.default_code;
           tipoprod = h1.category_sunat_code; 
           coduni = h1.uom_sunat_code;
           metodo = 'Costo promedio';
           
           period_name = dr.period_name;
          
           fecha_albaran = dr.fecha_albaran;
           pedido_compra = dr.pedido_compra;
           licitacion = dr.licitacion;
           doc_almac = dr.doc_almac;


          --- final de proceso de variables output

        
          ingreso =coalesce(dr.ingreso,0);
          salida =coalesce(dr.salida,0);
          --if dr.serial is not null then 
            debit=coalesce(dr.debit,0);
          --else
            --if dr.ubicacion_origen=8 then
              --debit =0;
            --else
              ---debit = coalesce(dr.debit,0);
            --end if;
          --end if;
          

          
            credit =coalesce(dr.credit,0);
          
          cadquiere =coalesce(dr.cadquiere,0);
          precprom = cprom;
          if cadquiere <=0::numeric then
            cadquiere=cprom;
          end if;
          if salida>0::numeric then
            credit = cadquiere * salida;
          end if;
          saldov = saldov + (debit - credit);
          saldof = saldof + (ingreso - salida);
          if saldof > 0::numeric then
            if esingreso= 'ingreso' or ingreso > 0::numeric then
              if saldof != 0 then
                cprom = saldov/saldof;
              else
                      cprom = saldov;
                 end if;
              if ingreso = 0 then
                      cadquiere = cprom;
              else
                  cadquiere =debit/ingreso;
              end if;
              --cprom = saldov / saldof;
              --cadquiere = debit / ingreso;
            else
              if salida = 0::numeric then
                if debit + credit > 0::numeric then
                  cprom = saldov / saldof;
                  cadquiere=cprom;
                end if;
              else
                credit = salida * cprom;
              end if;
            end if;
          else
            cprom = 0;
          end if;
            

          if saldov <= 0::numeric and saldof <= 0::numeric then
            dr.cprom = 0;
            cprom = 0;
          end if;
          --if cadquiere=0 then
          --  if trim(dr.operation_type) != '05' and trim(dr.operation_type) != '' and dr.operation_type is not null then
          --    cadquiere=precprom;
          --    debit = ingreso*cadquiere;
          --    credit=salida*cadquiere;
          --  end if;
          --end if;
          dr.debit = round(debit,2);
          dr.credit = round(credit,2);
          dr.cprom = round(cprom,8);
          dr.cadquiere = round(cadquiere,8);
          dr.credit = round(credit,2);
          dr.saldof = round(saldof,2);
          dr.saldov = round(saldov,8);
          if ingreso>0 then
            cu_entrada =debit/ingreso;
          else
            cu_entrada =debit;
          end if;

          if salida>0 then
            cu_salida =credit/salida;
          else
          cu_salida =credit;
          end if;

          RETURN NEXT;
        end if;
  end loop;
  --return query select * from vst_kardex_sunat where fecha_num(vst_kardex_sunat.fecha) between $1 and $2 and vst_kardex_sunat.product_id = ANY($3) and vst_kardex_sunat.location_id = ANY($4) order by location_id,product_id,fecha;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION get_kardex_v(integer, integer, integer[], integer[])
  OWNER TO odoo10;