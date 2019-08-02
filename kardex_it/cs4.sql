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
  OWNER TO openpg;