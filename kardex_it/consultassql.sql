create extension tablefunc;

  -- Function: public.fecha_num(date)

-- DROP FUNCTION public.fecha_num(date);

CREATE OR REPLACE FUNCTION public.fecha_num(date)
  RETURNS integer AS
$BODY$
    SELECT to_char($1, 'YYYYMMDD')::integer;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.fecha_num(date)
  OWNER TO openpg;




-- Function: public.getnumber(character varying)

-- DROP FUNCTION public.getnumber(character varying);

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
  OWNER TO openpg;




-- Function: public.getperiod(integer, date, boolean)

-- DROP FUNCTION public.getperiod(integer, date, boolean);

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
  inner join account_period on account_move.period_id = account_period.id
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
  OWNER TO openpg;


-- Function: public.getperiod(timestamp without time zone, boolean)

-- DROP FUNCTION public.getperiod(timestamp without time zone, boolean);

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
  OWNER TO openpg;

-- Function: public.getperiod(integer, timestamp without time zone, boolean)

-- DROP FUNCTION public.getperiod(integer, timestamp without time zone, boolean);

CREATE OR REPLACE FUNCTION public.getperiod(
    move_id integer,
    date_picking timestamp without time zone,
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
  inner join account_period on account_move.period_id = account_period.id
  where account_move.id=move_id1;
    ELSE 
  select account_period.name into res from account_period
  where date_start<=date_picking1 and date_stop>=date_picking1 and account_period.special=isspecial;
   END IF;
   return res;  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.getperiod(integer, timestamp without time zone, boolean)
  OWNER TO openpg;


-- Function: public.getserial(character varying)

-- DROP FUNCTION public.getserial(character varying);

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
  OWNER TO openpg;


-- Function: public.inicio_periodo(character varying)

-- DROP FUNCTION public.inicio_periodo(character varying);

CREATE OR REPLACE FUNCTION public.inicio_periodo(libro character varying)
  RETURNS date AS
$BODY$
    Select date_start from account_period where name= $1
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.inicio_periodo(character varying)
  OWNER TO openpg;



-- Function: public.periodo_num(character varying)

-- DROP FUNCTION public.periodo_num(character varying);

CREATE OR REPLACE FUNCTION public.periodo_num(character varying)
  RETURNS integer AS
$BODY$
    SELECT CASE WHEN substring($1,1,19) = 'Periodo de apertura' THEN (substring($1,21,4) || '00' )::integer ELSE
    (substring( $1,4,4) || substring($1 , 1,2)  )::integer END ;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.periodo_num(character varying)
  OWNER TO openpg;


-- Function: public.periodo_string(integer)

-- DROP FUNCTION public.periodo_string(integer);

CREATE OR REPLACE FUNCTION public.periodo_string(numero integer)
  RETURNS character varying AS
$BODY$
    SELECT CASE WHEN substring(numero::varchar,5,2) = '00' THEN 'Periodo de apertura ' || substring(numero::varchar,1,4) ELSE
    (substring(numero::varchar,5,2) || '/' ||substring(numero::varchar,1,4) )::varchar END;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.periodo_string(integer)
  OWNER TO openpg;




-- View: public.vst_account_currencyrate

-- DROP VIEW public.vst_account_currencyrate;

CREATE OR REPLACE VIEW public.vst_account_currencyrate AS 
 SELECT max(account_move_line.currency_rate_it) AS currency_rate,
    account_move_line.move_id,
    account_invoice.id AS invoice_id
   FROM account_move_line
     JOIN account_invoice ON account_move_line.move_id = account_invoice.move_id
  GROUP BY account_move_line.move_id, account_invoice.id;

ALTER TABLE public.vst_account_currencyrate
  OWNER TO openpg;




-- View: public.vst_ebi_eeff

-- DROP VIEW public.vst_ebi_eeff;

CREATE OR REPLACE VIEW public.vst_ebi_eeff AS 
 SELECT af.name::double precision AS "año",
    account_period.code AS periodo,
    account_account_type.name AS rubro,
        CASE
            WHEN account_account_type.group_balance IS NOT NULL THEN 'Balance'::character varying
            ELSE 'Naturaleza'::character varying
        END AS tipo_rubro,
    account_account.code AS cuenta,
    account_account.name AS nombrecuenta,
        CASE
            WHEN
            CASE
                WHEN account_account_type.group_balance IS NOT NULL THEN 'Balance'::character varying
                ELSE 'Naturaleza'::character varying
            END::text = 'Balance'::text THEN sum(account_move_line.debit - account_move_line.credit)
            ELSE sum(account_move_line.credit - account_move_line.debit)
        END AS saldo,
    account_account_type.order_balance,
    account_account_type.order_nature
   FROM account_move_line
     LEFT JOIN account_move ON account_move.id = account_move_line.move_id
     LEFT JOIN account_account ON account_account.id = account_move_line.account_id
     LEFT JOIN account_account_type ON account_account_type.id = account_account.user_type
     LEFT JOIN account_period ON account_period.id = account_move.period_id
     LEFT JOIN account_fiscalyear af ON af.id = account_period.fiscalyear_id
     LEFT JOIN account_journal ON account_journal.id = account_move.journal_id
  WHERE account_move.state::text = 'posted'::text AND (account_account_type.group_balance IS NOT NULL OR account_account_type.group_nature IS NOT NULL)
  GROUP BY af.name, account_period.code, account_account_type.name, (
        CASE
            WHEN account_account_type.group_balance IS NOT NULL THEN 'Balance'::character varying
            ELSE 'Naturaleza'::character varying
        END), account_account.name, account_account.code, account_account_type.order_balance, account_account_type.order_nature;

ALTER TABLE public.vst_ebi_eeff
  OWNER TO openpg;


-- View: public.vst_invoice_line

-- DROP VIEW public.vst_invoice_line;

CREATE OR REPLACE VIEW public.vst_invoice_line AS 
 SELECT avg(t.price_unit) AS price_unit,
    t.product_id,
    t.invoice_id,
    max(t.account_id) AS account_id
   FROM ( SELECT
                CASE
                    WHEN account_move_line.quantity > 0::numeric THEN (account_move_line.debit - account_move_line.credit) / account_move_line.quantity
                    ELSE account_move_line.debit - account_move_line.credit
                END AS price_unit,
            account_move_line.product_id,
            account_invoice.id AS invoice_id,
            account_move_line.account_id
           FROM account_move_line
             JOIN account_move ON account_move_line.move_id = account_move.id
             JOIN account_invoice ON account_move.id = account_invoice.move_id
          WHERE account_move_line.quantity IS NOT NULL AND account_move_line.product_id IS NOT NULL) t
  GROUP BY t.product_id, t.invoice_id
  ORDER BY t.invoice_id, t.product_id;

ALTER TABLE public.vst_invoice_line
  OWNER TO openpg;


-- View: public.vst_invoice_line_final

-- DROP VIEW public.vst_invoice_line_final;

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
  OWNER TO openpg;


CREATE OR REPLACE VIEW vst_kardex_credit_final AS 
        (         SELECT DISTINCT stock_location.complete_name, 
                    product_category.name AS categoria, 
                    product_product.name_template, account_move.date, 
                    account_period.name AS getperiod, 
                    ''::character varying AS ctanalitica, 
                    getserial(account_invoice.supplier_invoice_number) AS serial, 
                    getnumber(account_invoice.supplier_invoice_number)::character varying(10) AS getnumber, 
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
                    lpad(account_invoice.type_document_id::text, 2, '0'::text) AS doc_type_ope, 
                    account_account.id AS account_id, 
                    account_account.code AS account_invoice, 
                    it_type_document.code::text AS type_doc, 
                    COALESCE(account_invoice.supplier_invoice_number, ''::character varying) AS numdoc_cuadre, 
                    res_partner.type_number, 
                    account_invoice_line.id AS invoicelineid
                   FROM account_invoice_line
              JOIN account_invoice ON account_invoice_line.invoice_id = account_invoice.id
         JOIN product_uom ON account_invoice_line.uos_id = product_uom.id
    LEFT JOIN it_type_document ON account_invoice.type_document_id = it_type_document.id
   JOIN account_move ON account_invoice.move_id = account_move.id
   JOIN account_move_line ON account_move.id = account_move_line.move_id and account_move_line.product_id = account_invoice_line.product_id
   JOIN account_account ON account_move_line.account_id = account_account.id
   JOIN res_partner ON account_invoice.partner_id = res_partner.id
   JOIN product_product ON account_move_line.product_id = product_product.id
   JOIN product_template ON product_product.product_tmpl_id = product_template.id
   JOIN product_uom uomt ON product_template.uom_id = uomt.id
   JOIN product_category ON product_template.categ_id = product_category.id
   JOIN stock_location ON account_invoice_line.location_id = stock_location.id
   JOIN account_period ON account_move.period_id = account_period.id
   JOIN account_journal ON account_move_line.journal_id = account_journal.id
   LEFT JOIN stock_picking sp ON sp.invoice_id = account_invoice.id
   LEFT JOIN stock_move sm ON sm.picking_id = sp.id AND sm.product_id = product_product.id
  WHERE account_invoice.is_fixer = true
        UNION ALL 
                 SELECT DISTINCT stock_location.complete_name, 
                    product_category.name AS categoria, 
                    product_product.name_template, account_move.date, 
                    account_period.name AS getperiod, 
                    ''::character varying AS ctanalitica, 
                    getserial(account_invoice.supplier_invoice_number) AS serial, 
                    getnumber(account_invoice.supplier_invoice_number)::character varying(10) AS getnumber, 
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
                    lpad(account_invoice.type_document_id::text, 2, '0'::text) AS doc_type_ope, 
                    account_account.id AS account_id, 
                    account_account.code AS account_invoice, 
                    it_type_document.code::text AS type_doc, 
                    COALESCE(account_invoice.supplier_invoice_number, ''::character varying) AS numdoc_cuadre, 
                    res_partner.type_number, 0 AS invoicelineid
                   FROM account_invoice_line
              JOIN account_invoice ON account_invoice_line.invoice_id = account_invoice.id
         JOIN product_uom ON account_invoice_line.uos_id = product_uom.id
    LEFT JOIN it_type_document ON account_invoice.type_document_id = it_type_document.id
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
   JOIN account_period ON account_move.period_id = account_period.id
   JOIN account_journal ON account_move_line.journal_id = account_journal.id
   JOIN stock_picking sp ON sp.invoice_id = account_invoice.id
   JOIN stock_move sm ON sm.picking_id = sp.id AND sm.product_id = product_product.id
   LEFT JOIN stock_location ON account_invoice_line.location_id = stock_location.id
  WHERE account_invoice.is_fixer <> true AND account_invoice.type::text = 'in_refund'::text)
UNION ALL 
         SELECT DISTINCT stock_location.complete_name, 
            product_category.name AS categoria, product_product.name_template, 
            account_move.date, account_period.name AS getperiod, 
            ''::character varying AS ctanalitica, 
            getserial(account_invoice.supplier_invoice_number) AS serial, 
            getnumber(account_invoice.supplier_invoice_number)::character varying(10) AS getnumber, 
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
            lpad(account_invoice.type_document_id::text, 2, '0'::text) AS doc_type_ope, 
            account_account.id AS account_id, 
            account_account.code AS account_invoice, 
            it_type_document.code::text AS type_doc, 
            COALESCE(account_invoice.supplier_invoice_number, ''::character varying) AS numdoc_cuadre, 
            res_partner.type_number, 0 AS invoicelineid
           FROM account_invoice_line
      JOIN account_invoice ON account_invoice_line.invoice_id = account_invoice.id
   JOIN product_uom ON account_invoice_line.uos_id = product_uom.id
   LEFT JOIN it_type_document ON account_invoice.type_document_id = it_type_document.id
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
   JOIN account_period ON account_move.period_id = account_period.id
   JOIN account_journal ON account_move_line.journal_id = account_journal.id
   JOIN stock_picking sp ON sp.invoice_id = account_invoice.id
   JOIN stock_move sm ON sm.picking_id = sp.id AND sm.product_id = product_product.id
   LEFT JOIN stock_location ON account_invoice_line.location_id = stock_location.id
  WHERE account_invoice.is_fixer <> true AND account_invoice.type::text = 'in_invoice'::text;

ALTER TABLE vst_kardex_credit_final
  OWNER TO openpg;



-- View: public.vst_stock_move_final

-- DROP VIEW public.vst_stock_move_final;

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
    stock_move.product_uos,
    stock_move.location_id,
    stock_move.picking_type_id,
    stock_move.state,
    stock_move.product_id,
    stock_move.picking_id,
    stock_move.location_dest_id,
    COALESCE(stock_picking.invoice_id, 0) AS invoice_id,
        CASE
            WHEN stock_picking.use_date THEN stock_picking.date
            ELSE
            CASE
                WHEN ai.date_invoice IS NULL THEN stock_picking.date
                ELSE ai.date_invoice::timestamp without time zone
            END
        END AS date,
    stock_picking.name,
    stock_picking.partner_id,
    stock_picking.motivo_guia,
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
  OWNER TO openpg;




-- View: public.vst_kardex_fis_1_final

-- DROP VIEW public.vst_kardex_fis_1_final;

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
    k.type_number AS doc_partner
   FROM ( SELECT origen.complete_name AS origen,
            destino.complete_name AS destino,
            getserial(account_invoice.supplier_invoice_number) AS serial,
                CASE
                    WHEN vst_stock_move.invoice_id <> 0 THEN getnumber(account_invoice.supplier_invoice_number)::character varying(10)
                    ELSE vst_stock_move.name
                END AS nro,
            vst_stock_move.product_qty AS cantidad,
            vst_stock_move.product_qty AS ingreso,
            product_product.name_template AS producto,
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
            lpad(vst_stock_move.motivo_guia::text, 2, '0'::text)::character varying AS operation_type,
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
            COALESCE(account_invoice.supplier_invoice_number, ''::character varying) AS numdoc_cuadre,
            res_partner.type_number
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
             LEFT JOIN account_period ON account_invoice.period_id = account_period.id
             LEFT JOIN it_type_document ON account_invoice.type_document_id = it_type_document.id
             LEFT JOIN account_account aa_invoice_m ON vst_invoice_line.account_id = aa_invoice_m.id
             LEFT JOIN ir_property ipx ON ipx.res_id::text = ('product.template,'::text || product_template.id) AND ipx.name::text = 'cost_method'::text) k
     LEFT JOIN ( SELECT "substring"(ir_property.res_id::text, "position"(ir_property.res_id::text, ','::text) + 1)::integer AS categ_id,
            "substring"(ir_property.value_reference::text, "position"(ir_property.value_reference::text, ','::text) + 1)::integer AS account_id
           FROM ir_property
          WHERE ir_property.name::text = 'property_stock_valuation_account_id'::text) j ON k.category_id = j.categ_id
     LEFT JOIN account_account aa_cp ON j.account_id = aa_cp.id;

ALTER TABLE public.vst_kardex_fis_1_final
  OWNER TO openpg;




-- View: public.vst_kardex_fis_1_1_final

-- DROP VIEW public.vst_kardex_fis_1_1_final;

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
  OWNER TO openpg;


-- View: public.vst_kardex_sunat_final

-- DROP VIEW public.vst_kardex_sunat_final;

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
            vst_kardex_debitcredit_note.name_template AS producto,
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
            vst_kardex_debitcredit_note.type_number AS doc_partner,
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

ALTER TABLE public.vst_kardex_sunat_final
  OWNER TO openpg;


-- View: public.vst_naturaleza

-- DROP VIEW public.vst_naturaleza;

CREATE OR REPLACE VIEW public.vst_naturaleza AS 
 SELECT af.name::integer AS "Año",
    substr(ap.name::text, 0, 3)::integer AS "Mes",
    1 AS "Día",
    ap.name AS "Periodo",
    aml.debit - aml.credit AS "Balance",
    aaa.name AS "Cta.Analitica",
    concat(aa.code, '-', aa.name) AS "Cuenta",
    replace(aat.group_nature::text, 'N'::text, 'Grupo '::text) AS "Rubro_ERN",
    res_company.name AS "Compañía"
   FROM account_move am
     JOIN account_move_line aml ON aml.move_id = am.id
     JOIN account_period ap ON ap.id = am.period_id
     JOIN account_fiscalyear af ON af.id = ap.fiscalyear_id
     JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
     JOIN account_account aa ON aa.id = aml.account_id
     JOIN account_account_type aat ON aat.id = aa.user_type
     CROSS JOIN res_company
  WHERE am.state::text <> 'draft'::text AND aat.group_nature IS NOT NULL;

ALTER TABLE public.vst_naturaleza
  OWNER TO openpg;



-- View: public.vst_planilla_distribucion

-- DROP VIEW public.vst_planilla_distribucion;

CREATE OR REPLACE VIEW public.vst_planilla_distribucion AS 
 SELECT date_part('day'::text, ap.date_start) AS dia,
    date_part('month'::text, ap.date_start) AS mes,
    date_part('year'::text, ap.date_start) AS anio,
    he.codigo_trabajador,
    he.identification_id AS dni,
    (((he.first_name_complete::text || ' '::text) || he.last_name_father::text) || ' '::text) || he.last_name_mother::text AS empleado,
    hlc.name AS concepto_id,
        CASE
            WHEN (hcl.monto * hdgl.porcentaje::double precision / 100.00::double precision) <> 0::double precision THEN hcl.monto * hdgl.porcentaje::double precision / 100.00::double precision
            ELSE hcl.monto
        END AS monto,
    hdgl.porcentaje,
    aca.name AS cuenta_analitica,
    (aa.code::text || ' '::text) || aa.name::text AS cuenta_contable,
    rc.name AS company
   FROM hr_concepto_line hcl
     LEFT JOIN hr_lista_conceptos hlc ON hcl.concepto_id = hlc.id
     LEFT JOIN hr_tareo_line htl ON hcl.tareo_line_id = htl.id
     LEFT JOIN hr_tareo ht ON htl.tareo_id = ht.id
     LEFT JOIN account_period ap ON ht.periodo = ap.id
     LEFT JOIN hr_employee he ON htl.employee_id = he.id
     LEFT JOIN hr_distribucion_gastos hdg ON hdg.id = he.dist_c
     LEFT JOIN hr_distribucion_gastos_linea hdgl ON hdgl.distribucion_gastos_id = hdg.id
     LEFT JOIN account_analytic_account aca ON hdgl.analitica = aca.id
     LEFT JOIN hr_lista_conceptos_line hlcl ON hdgl.analitica = hlcl.analytic_id AND hlc.id = hlcl.lista_id
     LEFT JOIN account_account aa ON hlcl.account_id = aa.id
     CROSS JOIN res_company rc;

ALTER TABLE public.vst_planilla_distribucion
  OWNER TO openpg;



-- View: public.vst_verif_kardex

-- DROP VIEW public.vst_verif_kardex;

CREATE OR REPLACE VIEW public.vst_verif_kardex AS 
 SELECT row_number() OVER () AS id,
    t.ubicacion,
    t.origen,
    t.producto,
    t.albaran,
    t.referencia,
    t.fecha,
    t.tipo_comp,
    t.comprobante,
    t.periodo,
    t.valor
   FROM ( SELECT sl.complete_name AS ubicacion,
            og.complete_name AS origen,
            pp.name_template AS producto,
            sp.name AS albaran,
            sp.origin AS referencia,
                CASE
                    WHEN ai.id IS NULL THEN
                    CASE
                        WHEN ai2.id IS NULL THEN ai2.date_invoice::timestamp without time zone
                        ELSE sp.date
                    END
                    ELSE ai.date_invoice::timestamp without time zone
                END AS fecha,
                CASE
                    WHEN ai.id IS NULL THEN
                    CASE
                        WHEN ai2.id IS NULL THEN ' '::text::character varying
                        ELSE itd2.description
                    END
                    ELSE itd.description
                END AS tipo_comp,
                CASE
                    WHEN ai.id IS NULL THEN
                    CASE
                        WHEN ai2.id IS NULL THEN ' '::text::character varying
                        ELSE ai2.number
                    END
                    ELSE ai.number
                END AS comprobante,
                CASE
                    WHEN am.id IS NULL THEN
                    CASE
                        WHEN ai2.id IS NULL THEN ' '::text::character varying
                        ELSE ap2.name
                    END
                    ELSE ap.name
                END AS periodo,
                CASE
                    WHEN ai.id IS NULL AND sm.invoice_id IS NULL THEN 'Sin comprobante relacionado'::text
                    ELSE
                    CASE
                        WHEN ail.id IS NULL AND ail2.id IS NULL THEN 'Comprobante sin producto relacionado'::text
                        ELSE
                        CASE
                            WHEN am.id IS NULL AND am2.id IS NULL THEN 'Comprobante sin asiento contable'::text
                            ELSE
                            CASE
                                WHEN aml.id IS NULL AND aml2.id IS NULL THEN 'Verificar producto en asiento contable'::text
                                ELSE 'ok'::text
                            END
                        END
                    END
                END AS valor
           FROM stock_move sm
             JOIN stock_picking sp ON sm.picking_id = sp.id
             LEFT JOIN product_product pp ON sm.product_id = pp.id
             LEFT JOIN account_invoice ai ON sp.invoice_id = ai.id
             LEFT JOIN account_invoice ai2 ON sm.invoice_id = ai2.id
             LEFT JOIN account_invoice_line ail ON ai.id = ail.invoice_id AND sm.product_id = ail.product_id
             LEFT JOIN account_invoice_line ail2 ON ai2.id = ail2.invoice_id AND sm.product_id = ail2.product_id
             LEFT JOIN account_move am ON ai.move_id = am.id
             LEFT JOIN account_move am2 ON ai2.move_id = am2.id
             LEFT JOIN account_move_line aml ON aml.move_id = am.id AND sm.product_id = aml.product_id
             LEFT JOIN account_move_line aml2 ON aml2.move_id = am2.id AND sm.product_id = aml2.product_id
             LEFT JOIN stock_location sl ON sm.location_dest_id = sl.id
             LEFT JOIN stock_location og ON sm.location_id = og.id
             LEFT JOIN res_partner rp ON ai.partner_id = rp.id
             LEFT JOIN product_template pt ON pp.product_tmpl_id = pt.id
             LEFT JOIN it_type_document itd ON ai.type_document_id = itd.id
             LEFT JOIN it_type_document itd2 ON ai2.type_document_id = itd2.id
             LEFT JOIN account_period ap ON am.period_id = ap.id
             LEFT JOIN account_period ap2 ON am.period_id = ap2.id
          WHERE sl.usage::text = 'internal'::text AND pt.type::text = 'product'::text AND sm.state::text = 'done'::text AND sp.state::text = 'done'::text AND (og.usage::text <> ALL (ARRAY['production'::character varying::text, 'internal'::character varying::text, 'inventory'::character varying::text])) AND (ai.id IS NULL OR am.id IS NULL OR aml.id IS NULL OR ai2.id IS NULL)
          ORDER BY sp.origin, sp.name, pp.name_template) t
  WHERE t.valor <> 'ok'::text;

ALTER TABLE public.vst_verif_kardex
  OWNER TO openpg;





-- Function: public.get_balance_general(boolean, integer, integer)

-- DROP FUNCTION public.get_balance_general(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_balance_general(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(name character varying, grupo character varying, saldo numeric, orden integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select aat.name  , aat.group_balance,
CASE WHEN $1= false THEN
  (CASE WHEN aat.group_balance = 'B1' OR aat.group_balance = 'B2' THEN  sum(aml.debit)-sum(aml.credit) 
   ELSE sum(aml.credit)-sum(aml.debit)  END )
  --sum(aml.debit)-sum(aml.credit) 
ELSE
  (CASE WHEN aat.group_balance = 'B1' OR aat.group_balance = 'B2' THEN  sum(aml.debit_me)-sum(aml.credit_me) 
  ELSE sum(aml.credit_me)-sum(aml.debit_me)  END )
  --sum(aml.debit_me)-sum(aml.credit_me) 
END as saldo, aat.order_balance
from account_account aca
inner join account_account_type aat on aat.id = aca.user_type

inner join account_move_line aml on aml.account_id = aca.id
inner join account_move am on am.id = aml.move_id
inner join account_period ap on ap.id = aml.period_id
where periodo_num(ap.name) >= $2 and  periodo_num(ap.name) <= $3 and aat.group_balance IS NOT NULL
and am.state != 'draft'
group by aat.name, aat.group_balance, aat.order_balance
order by aat.order_balance,aat.name;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_balance_general(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_cajabanco_with_saldoinicial(boolean, integer, integer)

-- DROP FUNCTION public.get_cajabanco_with_saldoinicial(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_cajabanco_with_saldoinicial(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, cuentacode character varying, cuentaname character varying, debe numeric, haber numeric, divisa character varying, tipodecambio numeric, importedivisa numeric, codigo character varying, partner character varying, tipodocumento character varying, numero character varying, fechaemision date, fechavencimiento date, glosa character varying, ctaanalitica character varying, refconcil character varying, statefiltro character varying, mediopago character varying, ordenamiento integer, entfinan character varying, nrocta character varying, moneda character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,*
   FROM ( SELECT * from(
    SELECT ap.name AS periodo,
    aj.code AS libro,
    am.name AS voucher,
    aa.code AS cuentacode,
    aa.name AS cuentaname,
    CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
    CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
    rc.name AS divisa,

            CASE WHEN $1 THEN aml.currency_rate_it
            ELSE
    CASE WHEN rc.name ='USD' THEN aml.currency_rate_it ELSE Null::numeric END END AS tipodecambio,
    aml.amount_currency AS importedivisa,
    rp.type_number AS codigo,
    rp.name AS partner,
    itd.description AS tipodocumento,
    aml.nro_comprobante AS numero,
    aml.date AS fechaemision,
    aml.date_maturity AS fechavencimiento,
    aml.name AS glosa,
    aaa.name AS ctaanalitica,
    aml.reconcile_ref AS refconcil,
    am.state AS statefiltro,
    mp.code AS mediopago,
    1 AS ordenamiento,
    aa.cashbank_financy AS entfinan,
    aa.cashbank_number AS nrocta,
    COALESCE(rc.name, ( SELECT rc_1.name
     FROM res_company
       JOIN res_currency rc_1 ON rc_1.id = res_company.currency_id)) AS moneda
FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
  JOIN account_account aa ON aa.id = aml.account_id
         LEFT JOIN it_means_payment mp ON mp.id = aml.means_payment_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
                     LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE aa.type::text = 'liquidity'::text and periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
  and am.state != 'draft'
  
UNION ALL

SELECT periodo_string($2) AS periodo,
    Null::varchar AS libro,
    Null::varchar AS voucher,
    aa.code AS cuentacode,
    aa.name AS cuentaname,
    CASE WHEN $1 THEN (CASE WHEN sum(aml.debit_me) - sum(aml.credit_me) >0 THEN sum(aml.debit_me) - sum(aml.credit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN sum(aml.debit) - sum(aml.credit) ELSE 0 END) END AS debe,
    CASE WHEN $1 THEN (CASE WHEN sum(aml.credit_me) - sum(aml.debit_me) >0 THEN sum(aml.credit_me) - sum(aml.debit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.credit) - sum(aml.debit) >0 THEN sum(aml.credit) - sum(aml.debit) ELSE 0 END) END AS haber,
    Null::varchar AS divisa,
    Null::numeric AS tipodecambio,
    Null::numeric AS importedivisa,
    Null::varchar AS codigo,
    Null::varchar AS partner,
    Null::varchar AS tipodocumento,
    Null::varchar AS numero,
    Null::date AS fechaemision,
    Null::date AS fechavencimiento,
    'Saldo Inicial'::varchar AS glosa,
    Null::varchar AS ctaanalitica,
    Null::varchar AS refconcil,
    Null::varchar AS statefiltro,
    Null::varchar AS mediopago,
    0 AS ordenamiento,
    Null::varchar AS entfinan,
    Null::varchar AS nrocta,
    Null::varchar AS moneda
   FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
     JOIN account_account aa ON aa.id = aml.account_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE aa.type::text = 'liquidity'::text and periodo_num(ap.name) < $2
  and am.state != 'draft'
  group by aa.code, aa.name


  ) AS T
  order by cuentacode,ordenamiento, fechaemision
  
  ) AS M;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_cajabanco_with_saldoinicial(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_compra_1(boolean, integer, integer)

-- DROP FUNCTION public.get_compra_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_compra_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(comprobante character varying, am_id integer, clasifica character varying, base_impuesto numeric, monto numeric, record_shop character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
   SELECT account_move.dec_reg_nro_comprobante AS comprobante,
    account_move.id AS am_id,
    account_tax_code.name AS clasifica,
    CASE WHEN $1 THEN 
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END ) ELSE account_move_line.tax_amount END AS base_impuesto,
    CASE WHEN $1 THEN 
  (CASE
            WHEN account_journal.type::text = 'purchase_refund'::text THEN account_move_line.currency_rate_it*account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.currency_rate_it*account_move_line.tax_amount
        END)
    ELSE
        (CASE
            WHEN account_journal.type::text = 'purchase_refund'::text THEN account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.tax_amount
        END)
       END AS monto,
    account_tax_code.record_shop
   FROM account_move
     JOIN account_move_line ON account_move.id = account_move_line.move_id
     JOIN account_journal ON account_move_line.journal_id = account_journal.id AND account_move.journal_id = account_journal.id
     JOIN account_period ON account_move.period_id = account_period.id AND account_move.period_id = account_period.id
     LEFT JOIN it_type_document ON account_move_line.type_document_id = it_type_document.id AND account_move.dec_mod_type_document_id = it_type_document.id AND account_move.dec_reg_type_document_id = it_type_document.id
     LEFT JOIN res_partner ON account_move.partner_id = res_partner.id AND account_move_line.partner_id = res_partner.id
     LEFT JOIN it_type_document_partner ON res_partner.type_document_id = it_type_document_partner.id
     JOIN account_tax_code ON account_move_line.tax_code_id = account_tax_code.id
  WHERE account_journal.register_sunat::text = '1'::text and periodo_num(account_period.name) >= $2 and periodo_num(account_period.name) <= $3
  and account_move.state != 'draft'
  ORDER BY account_move.dec_reg_nro_comprobante;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_compra_1(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_compra_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_compra_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_compra_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(am_id integer, "1" numeric, "2" numeric, "3" numeric, "4" numeric, "5" numeric, "6" numeric, "7" numeric, "8" numeric, "9" numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 

  SELECT crosstab.am_id,
    crosstab."1",
    crosstab."2",
    crosstab."3",
    crosstab."4",
    crosstab."5",
    crosstab."6",
    crosstab."7",
    crosstab."8",
    crosstab."9"
   FROM crosstab('SELECT c1.am_id ,c1.record_shop,
  sum(c1.monto) as monto FROM get_compra_1(' || $1 || ',' || $2 || ','|| $3 || ') as c1
  GROUP BY c1.am_id, c1.record_shop
  ORDER BY 1,2,3'::text, '  select m from generate_series(1,9) m'::text) crosstab(am_id integer, "1" numeric, "2" numeric, "3" numeric, "4" numeric, "5" numeric, "6" numeric, "7" numeric, "8" numeric, "9" numeric);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_compra_1_1(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_compra_1_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_compra_1_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_compra_1_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, am_id integer, periodo character varying, libro character varying, voucher character varying, fechaemision date, fechavencimiento date, tipodocumento character varying, serie text, numero text, tdp character varying, ruc character varying, razonsocial character varying, bioge numeric, biogeng numeric, biong numeric, cng numeric, isc numeric, igva numeric, igvb numeric, igvc numeric, otros numeric, total numeric, comprobante character varying, moneda character varying, tc numeric, fechad date, numerod character varying, fechadm date, td character varying, anio character varying, seried text, numerodd text) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.am_id,
    t.periodo,
    t.libro,
    t.voucher,
    t.fechaemision,
    t.fechavencimiento,
    t.tipodocumento,
    t.serie,
    t.numero,
    t.tdp,
    t.ruc,
    t.razonsocial,
    t.bioge,
    t.biogeng,
    t.biong,
    t.cng,
    t.isc,
    t.igva,
    t.igvb,
    t.igvc,
    t.otros,
    t.total,
    t.comprobantenrodomicilio,
    t.moneda,
    t.tc,
    t.fechad,
    t.numerod,
    t.fechadm,
    t.td,
    t.anio,
    t.seried,
    t.numerodd
   FROM ( SELECT pr.am_id,
            round(pr.bioge, 2) AS bioge,
            round(pr.biogeng, 2) AS biogeng,
            round(pr.biong, 2) AS biong,
            round(pr.cng, 2) AS cng,
            round(pr.isc, 2) AS isc,
            round(pr.otros, 2) AS otros,
            round(pr.igva, 2) AS igva,
            round(pr.igvb, 2) AS igvb,
            round(pr.igvc, 2) AS igvc,
            round(pr.total, 2) AS total,
                CASE
                    WHEN itd.id = mp.no_home_document_id OR itd.id = mp.no_home_debit_document_id OR itd.id = mp.no_home_credit_document_id THEN am.dec_reg_nro_comprobante
                    ELSE NULL::character varying
                END AS comprobantenrodomicilio,
            aj.code AS libro,
            ap.name AS periodo,
            am.name AS voucher,
            am.date AS fechaemision,
            am.com_det_date_maturity AS fechavencimiento,
            itd.code AS tipodocumento,
                CASE
                    WHEN itd.id = mp.no_home_document_id OR itd.id = mp.no_home_debit_document_id OR itd.id = mp.no_home_credit_document_id THEN NULL::text
                    ELSE
                    CASE
                        WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN NULL::text
                        ELSE "substring"(am.dec_reg_nro_comprobante::text, 0, "position"(am.dec_reg_nro_comprobante::text, '-'::text))
                    END
                END AS serie,
                CASE
                    WHEN itd.id = mp.no_home_document_id OR itd.id = mp.no_home_debit_document_id OR itd.id = mp.no_home_credit_document_id THEN NULL::text
                    ELSE
                    CASE
                        WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN am.dec_reg_nro_comprobante::text
                        ELSE "substring"(am.dec_reg_nro_comprobante::text, "position"(am.dec_reg_nro_comprobante::text, '-'::text) + 1)
                    END
                END AS numero,
            itdp.code AS tdp,
            rp.type_number AS ruc,
            rp.name AS razonsocial,
            rc.name AS moneda,

            CASE WHEN $1 THEN round(am.com_det_type_change, 3)
            ELSE
            CASE WHEN rc.name = 'USD' THEN round(am.com_det_type_change, 3) ELSE Null::numeric END END AS tc,
            am.com_det_date AS fechad,
            am.com_det_number AS numerod,
            apercep.fecha AS fechadm,
            itd2.code AS td,
                CASE
                    WHEN itd.id = mp.export_document_id THEN date_part('year'::text, am.date)::character varying(50)
                    ELSE NULL::character varying(50)
                END AS anio,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN ''::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, 0, "position"(am.dec_mod_nro_comprobante::text, '-'::text))
                END AS seried,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN am.dec_mod_nro_comprobante::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, "position"(am.dec_mod_nro_comprobante::text, '-'::text) + 1)
                END AS numerodd
           FROM ( SELECT vst_reg_compras_1_1.am_id,
                    sum(vst_reg_compras_1_1."1") AS bioge,
                    sum(vst_reg_compras_1_1."2") AS biogeng,
                    sum(vst_reg_compras_1_1."3") AS biong,
                    sum(vst_reg_compras_1_1."4") AS cng,
                    sum(vst_reg_compras_1_1."5") AS isc,
                    sum(vst_reg_compras_1_1."6") AS otros,
                    sum(vst_reg_compras_1_1."7") AS igva,
                    sum(vst_reg_compras_1_1."8") AS igvb,
                    sum(vst_reg_compras_1_1."9") AS igvc,
                    COALESCE(sum(vst_reg_compras_1_1."1"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."2"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."3"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."4"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."5"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."6"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."7"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."8"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."9"), 0::numeric) AS total
                   FROM get_compra_1_1($1,$2,$3) as vst_reg_compras_1_1
                  GROUP BY vst_reg_compras_1_1.am_id) pr
             JOIN account_move am ON am.id = pr.am_id
             JOIN account_journal aj ON aj.id = am.journal_id
             JOIN account_period ap ON ap.id = am.period_id
             LEFT JOIN it_type_document itd ON itd.id = am.dec_reg_type_document_id
             LEFT JOIN res_partner rp ON rp.id = am.partner_id
             LEFT JOIN it_type_document_partner itdp ON itdp.id = rp.type_document_id
             LEFT JOIN res_currency rc ON rc.id = am.com_det_currency
             LEFT JOIN account_invoice ai ON ai.move_id = am.id
             LEFT JOIN account_perception apercep ON apercep.father_invoice_id = ai.id
             LEFT JOIN account_invoice ai_hijo ON ai_hijo.supplier_invoice_number = apercep.comprobante and ai.type = ai_hijo.type
             LEFT JOIN it_type_document itd2 ON itd2.id = am.dec_mod_type_document_id
             CROSS JOIN main_parameter mp
          WHERE (apercep.id IN ( SELECT min(adr_1.id) AS min
                   FROM account_move am_1
                     JOIN account_invoice ai_1 ON ai_1.move_id = am_1.id
                     JOIN account_perception adr_1 ON adr_1.father_invoice_id = ai_1.id
                     JOIN account_invoice ai_hijo_1 ON ai_hijo_1.supplier_invoice_number = adr_1.comprobante and ai_1.type = ai_hijo_1.type
                  GROUP BY ai_1.id)) OR ai_hijo.* IS NULL
          ORDER BY ap.name, aj.code, am.name) t;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_compra_1_1_1(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_estado_funcion(boolean, integer, integer)

-- DROP FUNCTION public.get_estado_funcion(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_estado_funcion(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(name character varying, grupo character varying, saldo numeric, orden integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select aat.name , aat.group_function,
CASE WHEN $1= false THEN
   ((sum(aml.credit)-sum(aml.debit))   )
  --((sum(aml.debit)-sum(aml.credit))   )
ELSE
   ( (sum(aml.credit_me)-sum(aml.debit_me))   )
  --( (sum(aml.debit_me)-sum(aml.credit_me))   )
END as saldo, aat.order_function
from account_account aa
inner join account_account_type aat on aat.id = aa.user_type
inner join account_move_line aml on aml.account_id = aa.id
inner join account_move am on am.id = aml.move_id
inner join account_period ap on ap.id = aml.period_id
where periodo_num(ap.name) >= $2 and  periodo_num(ap.name) <= $3 and aat.group_function IS NOT NULL
and am.state != 'draft'
group by aat.name, aat.group_function, aat.order_function
order by aat.order_function,aat.name;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_estado_funcion(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_estado_nature(boolean, integer, integer)

-- DROP FUNCTION public.get_estado_nature(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_estado_nature(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(name character varying, grupo character varying, saldo numeric, orden integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select aat.name , aat.group_nature,
CASE WHEN $1= false THEN
  ((sum(aml.credit)-sum(aml.debit)) )
  --((sum(aml.debit)-sum(aml.credit)) )
ELSE
   ( (sum(aml.credit_me)-sum(aml.debit_me))  )
  --( (sum(aml.debit_me)-sum(aml.credit_me))  )
END as saldo, aat.order_nature
from account_account aa

inner join account_account_type aat on aat.id = aa.user_type
inner join account_move_line aml on aml.account_id = aa.id
inner join account_move am on am.id = aml.move_id
inner join account_period ap on ap.id = aml.period_id
where periodo_num(ap.name) >= $2 and  periodo_num(ap.name) <= $3 and aat.group_nature IS NOT NULL
and am.state != 'draft'
group by aat.name, aat.group_nature, aat.order_nature
order by aat.order_nature,aat.name;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_estado_nature(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_flujo_efectivo(boolean, integer, integer, integer)

-- DROP FUNCTION public.get_flujo_efectivo(boolean, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.get_flujo_efectivo(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer,
    IN period_saldo_inicial integer)
  RETURNS TABLE(periodo character varying, code character varying, concept character varying, debe numeric, haber numeric, saldo numeric, orden integer, grupo character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
$3 := $2;
END IF;

RETURN QUERY

(
select
periodo_string($4), ' '::varchar as code,'Saldo Inicial' as concept,
CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END as debe,
CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END as haber,
CASE WHEN $1 THEN sum(aml.debit_me)- sum(aml.credit_me) ELSE sum(aml.debit)- sum(aml.credit) END as saldo,
-1 as orden, 'E7'::varchar as "group"
from account_move_line aml
inner join account_move am on am.id = aml.move_id
inner join account_account aa on aa.id = aml.account_id
inner join account_period ap on ap.id = am.period_id
where aa.code like '10%' and periodo_num(ap.name)>=(substring($4::varchar,1,4) || '00' )::numeric and periodo_num(ap.name)<=$4
and am.state != 'draft'
)
UNION ALL
(
select
ap.name, ace.code,ace.concept,
CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END as debe,
CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END as haber,
CASE WHEN $1 THEN sum(aml.credit_me)- sum(aml.debit_me) ELSE sum(aml.credit)- sum(aml.debit) END as saldo,
ace.order as orden, ace."group"
from account_move_line aml
inner join account_move am on am.id = aml.move_id
inner join account_account aa on aa.id = aml.account_id
inner join account_config_efective ace on ace.id = aa.fefectivo_id
inner join account_period ap on ap.id = am.period_id
where aa.fefectivo_id is not null and periodo_num(ap.name)>=$2 and periodo_num(ap.name)<=$3
and am.state != 'draft' and am.id in ( select distinct am.id from account_move am inner join account_move_line aml on aml.move_id = am.id inner join account_account aa on aa.id = aml.account_id where aa.code like '10%' )
group by ap.name,ace.code , ace.concept, ace.order, ace."group"
order by ace.order);

END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_flujo_efectivo(boolean, integer, integer, integer)
  OWNER TO openpg;

-- Function: public.get_flujo_efectivo(boolean, integer, integer)

-- DROP FUNCTION public.get_flujo_efectivo(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_flujo_efectivo(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(periodo character varying, code character varying, concept character varying, debe numeric, haber numeric, saldo numeric, orden integer, grupo character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select 
ap.name, ace.code,ace.concept,
CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END as debe, 
CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END as haber, 
CASE WHEN $1 THEN sum(aml.debit_me)- sum(aml.credit_me) ELSE sum(aml.debit)- sum(aml.credit) END as saldo, 
ace.order as orden, ace."group"
from account_move_line aml 
inner join account_move am on am.id = aml.move_id
inner join account_account aa on aa.id = aml.account_id
inner join account_config_efective ace on ace.id = aml.fefectivo_id
inner join account_period ap on ap.id = aml.period_id
where fefectivo_id is not null and aa.type = 'liquidity' and periodo_num(ap.name)>=$2 and periodo_num(ap.name)<=$3
and am.state != 'draft'
group by ap.name,ace.code , ace.concept, ace.order, ace."group"
order by ace.order;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_flujo_efectivo(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_hoja_trabajo_detalle(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, clasificationactual character varying, levelactual character varying, cuentaactual character varying, clasification character varying, level character varying, periodo character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.clasificationactual,
    t.levelactual,
    t.cuentaactual,
    t.clasification,
    t.level,
    t.periodo,
    t.cuenta,
    t.descripcion,
    t.debe,
    t.haber,
    t.saldodeudor,
    t.saldoacredor,
    t.activo,
    t.pasivo,
    t.perdidasnat,
    t.ganancianat,
    t.perdidasfun,
    t.gananciafun
   FROM ( SELECT *, 

                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe > M.haber THEN M.debe - M.haber
                    ELSE 0::numeric
                END AS activo,
                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe < M.haber THEN M.haber - M.debe
                    ELSE 0::numeric
                END AS pasivo,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasnat,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS ganancianat,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasfun,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS gananciafun


    FROM (

    SELECT aapadre.clasification_sheet AS clasificationactual,
            aa.level_sheet AS levelactual,
            aa.code AS cuentaactual,
            aa.clasification_sheet AS clasification,
            aapadre.level_sheet AS level,
            ap.name AS periodo,
            aapadre.code AS cuenta,
            aapadre.name AS descripcion,
            CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END AS debe,
            CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END AS haber,
            CASE WHEN $1 THEN (CASE
                    WHEN sum(aml.debit_me) > sum(aml.credit_me) THEN sum(aml.debit_me) - sum(aml.credit_me)
                    ELSE 0::numeric
                END)
            ELSE
                (CASE
                    WHEN sum(aml.debit) > sum(aml.credit) THEN sum(aml.debit) - sum(aml.credit)
                    ELSE 0::numeric
                END) END AS saldodeudor,
             CASE WHEN $1 THEN
             (CASE
                    WHEN sum(aml.debit_me) < sum(aml.credit_me) THEN sum(aml.credit_me) - sum(aml.debit_me)
                    ELSE 0::numeric
                END)
             ELSE
                (CASE
                    WHEN sum(aml.debit) < sum(aml.credit) THEN sum(aml.credit) - sum(aml.debit)
                    ELSE 0::numeric
                END) END AS saldoacredor
                
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             JOIN account_account aapadre ON aapadre.code::text = "substring"(''::text || aa.code::text, 0, 3)
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
          WHERE aapadre.level_sheet IS NOT NULL and aa.level_sheet IS NOT NULL and periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
          and am.state != 'draft'
          GROUP BY aa.code, aa.level_sheet, aa.clasification_sheet, ap.name, aapadre.code, aapadre.level_sheet, aapadre.clasification_sheet, aapadre.name
          ORDER BY ap.name, aapadre.code)as  M ) t;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_hoja_trabajo_detalle_balance(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_balance(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_balance(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY    
select row_number() OVER () AS id,T.* from (
select M.cuenta,M.descripcion, sum(M.debe),sum(M.haber),
CASE WHEN sum(M.saldodeudor) -sum(M.saldoacredor)> 0 THEN sum(M.saldodeudor) -sum(M.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(M.saldoacredor) -sum(M.saldodeudor)> 0 THEN sum(M.saldoacredor) -sum(M.saldodeudor) ELSE 0 END as saldoacredor,
CASE WHEN sum(M.activo)-sum(M.pasivo)>0 THEN sum(M.activo)-sum(M.pasivo) ELSE 0 END as activo,
CASE WHEN sum(M.pasivo)-sum(M.activo)>0 THEN sum(M.pasivo)-sum(M.activo) ELSE 0 END as pasivo,
CASE WHEN sum(M.perdidasnat)-sum(M.ganancianat) >0 THEN sum(M.perdidasnat)-sum(M.ganancianat) ELSE 0 END as perdidasnat,
CASE WHEN sum(M.ganancianat)-sum(M.perdidasnat) >0 THEN sum(M.ganancianat)-sum(M.perdidasnat) ELSE 0 END as ganancianat,
CASE WHEN sum(M.perdidasfun)-sum(M.gananciafun) >0 THEN sum(M.perdidasfun)-sum(M.gananciafun) ELSE 0 END as perdidasfun,
CASE WHEN sum(M.gananciafun)-sum(M.perdidasfun) >0 THEN sum(M.gananciafun)-sum(M.perdidasfun) ELSE 0 END as gananciafun
from get_hoja_trabajo_detalle($1,$2,$3) as M
group by M.cuenta,M.descripcion
order by M.cuenta
) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_balance(boolean, integer, integer)
  OWNER TO openpg;

-- Function: public.get_hoja_trabajo_detalle_registro(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_registro(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_registro(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY    
select row_number() OVER () AS id,T.* from (
select M.cuentaactual,aa.name as descripcion, sum(M.debe),sum(M.haber),
CASE WHEN sum(M.saldodeudor) -sum(M.saldoacredor)> 0 THEN sum(M.saldodeudor) -sum(M.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(M.saldoacredor) -sum(M.saldodeudor)> 0 THEN sum(M.saldoacredor) -sum(M.saldodeudor) ELSE 0 END as saldoacredor,
CASE WHEN sum(M.activo)-sum(M.pasivo)>0 THEN sum(M.activo)-sum(M.pasivo) ELSE 0 END as activo,
CASE WHEN sum(M.pasivo)-sum(M.activo)>0 THEN sum(M.pasivo)-sum(M.activo) ELSE 0 END as pasivo,
CASE WHEN sum(M.perdidasnat)-sum(M.ganancianat) >0 THEN sum(M.perdidasnat)-sum(M.ganancianat) ELSE 0 END as perdidasnat,
CASE WHEN sum(M.ganancianat)-sum(M.perdidasnat) >0 THEN sum(M.ganancianat)-sum(M.perdidasnat) ELSE 0 END as ganancianat,
CASE WHEN sum(M.perdidasfun)-sum(M.gananciafun) >0 THEN sum(M.perdidasfun)-sum(M.gananciafun) ELSE 0 END as perdidasfun,
CASE WHEN sum(M.gananciafun)-sum(M.perdidasfun) >0 THEN sum(M.gananciafun)-sum(M.perdidasfun) ELSE 0 END as gananciafun
from get_hoja_trabajo_detalle($1,$2,$3) as M
inner join account_account aa ON aa.code = cuentaactual
group by M.cuentaactual,aa.name) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_registro(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_hoja_trabajo_detalle_six(boolean, integer, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_six(boolean, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_six(
    IN boolean,
    IN integer,
    IN integer,
    IN integer)
  RETURNS TABLE(id bigint, level character varying, clasificationactual character varying, cuenta text, description character varying, levelactual character varying, clasification character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select row_number() OVER () AS id,* from (
select '0'::varchar as level,'0'::varchar as clasificationactual,CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END as cuenta,aa.name as description, '0'::varchar as levelactual, '0'::varchar as clasification, 
sum(T.debe) as debe,
sum(T.haber) as haber,

CASE WHEN sum(T.saldodeudor) - sum(T.saldoacredor)>0 THEN  sum(T.saldodeudor) - sum(T.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(T.saldoacredor) - sum(T.saldodeudor)>0 THEN  sum(T.saldoacredor) - sum(T.saldodeudor) ELSE 0 END as saldoacredor,

CASE WHEN sum(T.activo) - sum(T.pasivo)>0 THEN  sum(T.activo) - sum(T.pasivo) ELSE 0 END as activo,
CASE WHEN sum(T.pasivo) - sum(T.activo)>0 THEN  sum(T.pasivo) - sum(T.activo) ELSE 0 END as pasivo,

CASE WHEN sum(T.perdidasnat) - sum(T.ganancianat)>0 THEN  sum(T.perdidasnat) - sum(T.ganancianat) ELSE 0 END as perdidasnat,
CASE WHEN sum(T.ganancianat) - sum(T.perdidasnat)>0 THEN  sum(T.ganancianat) - sum(T.perdidasnat) ELSE 0 END as ganancianat,


CASE WHEN sum(T.perdidasfun) - sum(T.gananciafun)>0 THEN  sum(T.perdidasfun) - sum(T.gananciafun) ELSE 0 END as perdidasfun,
CASE WHEN sum(T.gananciafun) - sum(T.perdidasfun)>0 THEN  sum(T.gananciafun) - sum(T.perdidasfun) ELSE 0 END as gananciafun

from get_hoja_trabajo_detalle( $1,$2,$3) as T
left join account_account aa on aa.name = CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END 
group by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END, aa.name 
order by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END
) AS T;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_six(boolean, integer, integer, integer)
  OWNER TO openpg;



-- Function: public.get_hoja_trabajo_detalle_temporal(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_temporal(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_temporal(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, clasificationactual character varying, levelactual character varying, cuentaactual character varying, clasification character varying, level character varying, periodo character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.clasificationactual,
    t.levelactual,
    t.cuentaactual,
    t.clasification,
    t.level,
    t.periodo,
    t.cuenta,
    t.descripcion,
    t.debe,
    t.haber,
    t.saldodeudor,
    t.saldoacredor,
    t.activo,
    t.pasivo,
    t.perdidasnat,
    t.ganancianat,
    t.perdidasfun,
    t.gananciafun
   FROM ( SELECT *, 

                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe > M.haber THEN M.debe - M.haber
                    ELSE 0::numeric
                END AS activo,
                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe < M.haber THEN M.haber - M.debe
                    ELSE 0::numeric
                END AS pasivo,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasnat,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS ganancianat,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasfun,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS gananciafun


    FROM (

    SELECT aapadre.clasification_sheet AS clasificationactual,
            aa.level_sheet AS levelactual,
            aa.code AS cuentaactual,
            aa.clasification_sheet AS clasification,
            aapadre.level_sheet AS level,
            ap.name AS periodo,
            aapadre.code AS cuenta,
            aapadre.name AS descripcion,
            CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END AS debe,
            CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END AS haber,
            CASE WHEN $1 THEN (CASE
                    WHEN sum(aml.debit_me) > sum(aml.credit_me) THEN sum(aml.debit_me) - sum(aml.credit_me)
                    ELSE 0::numeric
                END)
            ELSE
                (CASE
                    WHEN sum(aml.debit) > sum(aml.credit) THEN sum(aml.debit) - sum(aml.credit)
                    ELSE 0::numeric
                END) END AS saldodeudor,
             CASE WHEN $1 THEN
             (CASE
                    WHEN sum(aml.debit_me) < sum(aml.credit_me) THEN sum(aml.credit_me) - sum(aml.debit_me)
                    ELSE 0::numeric
                END)
             ELSE
                (CASE
                    WHEN sum(aml.debit) < sum(aml.credit) THEN sum(aml.credit) - sum(aml.debit)
                    ELSE 0::numeric
                END) END AS saldoacredor
                
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             LEFT JOIN account_account aapadre ON aapadre.code::text = "substring"(''::text || aa.code::text, 0, 3)
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
          WHERE aapadre.level_sheet IS NULL and aa.level_sheet IS NULL and periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
          and am.state != 'draft'
          GROUP BY aa.code, aa.level_sheet, aa.clasification_sheet, ap.name, aapadre.code, aapadre.level_sheet, aapadre.clasification_sheet, aapadre.name
          ORDER BY ap.name, aapadre.code)as  M ) t;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_temporal(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_hoja_trabajo_simple(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, clasificationactual character varying, levelactual character varying, clasification character varying, level character varying, periodo character varying, cuenta character varying, cuentaactual character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.clasificationactual,
    t.levelactual,
    t.clasification,
    t.level,
    t.periodo,
    t.cuenta,
    t.cuentaactual,
    t.descripcion,
    t.debe,
    t.haber,
    t.saldodeudor,
    t.saldoacredor
   FROM ( SELECT aa.clasification_sheet AS clasificationactual,
            aa.level_sheet AS levelactual,
            aapadre.clasification_sheet AS clasification,
            aapadre.level_sheet AS level,
            ap.name AS periodo,
            aapadre.code AS cuenta,
            aa.code AS cuentaactual,
            aapadre.name AS descripcion,
            CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END AS debe,
            CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END AS haber,
            CASE WHEN $1 THEN (CASE
                    WHEN sum(aml.debit_me) > sum(aml.credit_me) THEN sum(aml.debit_me) - sum(aml.credit_me)
                    ELSE 0::numeric
                END)
            ELSE
                (CASE
                    WHEN sum(aml.debit) > sum(aml.credit) THEN sum(aml.debit) - sum(aml.credit)
                    ELSE 0::numeric
                END) END AS saldodeudor,
             CASE WHEN $1 THEN
             (CASE
                    WHEN sum(aml.debit_me) < sum(aml.credit_me) THEN sum(aml.credit_me) - sum(aml.debit_me)
                    ELSE 0::numeric
                END)
             ELSE
                (CASE
                    WHEN sum(aml.debit) < sum(aml.credit) THEN sum(aml.credit) - sum(aml.debit)
                    ELSE 0::numeric
                END) END AS saldoacredor
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             JOIN account_account aapadre ON aapadre.code::text = "substring"(''::text || aa.code::text, 0, 3)
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
             where periodo_num(ap.name) >=$2 and  periodo_num(ap.name) <=$3
             and am.state != 'draft'
          GROUP BY aa.code, aa.level_sheet, aa.clasification_sheet, ap.name, aapadre.code, aapadre.level_sheet, aapadre.clasification_sheet, aapadre.name
          ORDER BY ap.name, aapadre.code) t;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_hoja_trabajo_simple_balance(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple_balance(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple_balance(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
   select row_number() OVER () AS id,* from (
select M.cuenta,M.descripcion, sum(M.debe) as debe,sum(M.haber) as haber ,
CASE WHEN sum(M.saldodeudor) - sum(M.saldoacredor) >0 THEN sum(M.saldodeudor) - sum(M.saldoacredor) ELSE 0 END  as saldodeudor,
CASE WHEN sum(M.saldodeudor) - sum(M.saldoacredor) <0 THEN sum(M.saldoacredor) - sum(M.saldodeudor) ELSE 0 END  as saldoacredor
from get_hoja_trabajo_simple($1,$2,$3) as M
group by M.cuenta,M.descripcion
order by M.cuenta) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple_balance(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_hoja_trabajo_simple_registro(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple_registro(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple_registro(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
   select row_number() OVER () AS id,* from (
select hoja.cuentaactual as cuenta,aa.name as descripcion, sum(hoja.debe) as debe,sum(hoja.haber) as haber ,
CASE WHEN sum(hoja.saldodeudor) - sum(hoja.saldoacredor) >0 THEN sum(hoja.saldodeudor) - sum(hoja.saldoacredor) ELSE 0 END  as saldodeudor,
CASE WHEN sum(hoja.saldodeudor) - sum(hoja.saldoacredor) <0 THEN sum(hoja.saldoacredor) - sum(hoja.saldodeudor) ELSE 0 END  as saldoacredor
from get_hoja_trabajo_simple($1,$2,$3) as hoja
inner join account_account aa on aa.code= hoja.cuentaactual 
group by hoja.cuentaactual,aa.name
order by hoja.cuentaactual) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple_registro(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_hoja_trabajo_simple_six(boolean, integer, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple_six(boolean, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple_six(
    IN boolean,
    IN integer,
    IN integer,
    IN integer)
  RETURNS TABLE(id bigint, level character varying, clasificationactual character varying, cuenta text, description character varying, levelactual character varying, clasification character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select row_number() OVER () AS id,* from (
select '0'::varchar as level,'0'::varchar as clasificationactual,CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END as cuenta,aa.name as description, '0'::varchar as levelactual, '0'::varchar as clasification, 
sum(T.debe) as debe,
sum(T.haber) as haber,

CASE WHEN sum(T.saldodeudor) - sum(T.saldoacredor)>0 THEN  sum(T.saldodeudor) - sum(T.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(T.saldoacredor) - sum(T.saldodeudor)>0 THEN  sum(T.saldoacredor) - sum(T.saldodeudor) ELSE 0 END as saldoacredor

from get_hoja_trabajo_simple( $1,$2,$3) as T
left join account_account aa on aa.name = CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END 
group by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END, aa.name 
order by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END
) AS T;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple_six(boolean, integer, integer, integer)
  OWNER TO openpg;



-- Function: public.get_honorarios_1(boolean, integer, integer)

-- DROP FUNCTION public.get_honorarios_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_honorarios_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(comprobante character varying, am_id integer, clasifica character varying, base_impuesto numeric, monto numeric, record_fees character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT account_move.dec_reg_nro_comprobante AS comprobante,
    account_move.id AS am_id,
    account_tax_code.name AS clasifica,
    CASE WHEN $1 THEN  
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END )
      
      ELSE account_move_line.tax_amount END AS base_impuesto,
    CASE WHEN $1 THEN  
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END )
      ELSE account_move_line.tax_amount END AS monto,
    account_tax_code.record_fees
   FROM account_move
     JOIN account_move_line ON account_move.id = account_move_line.move_id
     JOIN account_journal ON account_move_line.journal_id = account_journal.id AND account_move.journal_id = account_journal.id
     JOIN account_period ON account_move.period_id = account_period.id AND account_move.period_id = account_period.id
     
     LEFT JOIN it_type_document ON account_move_line.type_document_id = it_type_document.id AND account_move.dec_mod_type_document_id = it_type_document.id AND account_move.dec_reg_type_document_id = it_type_document.id
     LEFT JOIN res_partner ON account_move.partner_id = res_partner.id AND account_move_line.partner_id = res_partner.id
     LEFT JOIN it_type_document_partner ON res_partner.type_document_id = it_type_document_partner.id
     JOIN account_tax_code ON account_move_line.tax_code_id = account_tax_code.id
  WHERE account_tax_code.record_fees IS NOT NULL and periodo_num(account_period.name) >= $2 and periodo_num(account_period.name) <= $3
  and account_move.state != 'draft'
  ORDER BY account_move.dec_reg_nro_comprobante;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_honorarios_1(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_honorarios_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_honorarios_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_honorarios_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(am_id integer, "1" numeric, "2" numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
 SELECT crosstab.am_id,
    crosstab."1",
    crosstab."2"
   FROM crosstab('SELECT h1.am_id ,h1.record_fees,
  sum(h1.monto) as monto FROM get_honorarios_1(' || $1 || ',' || $2 || ','|| $3 || ') as h1
  GROUP BY h1.am_id, h1.record_fees
  ORDER BY 1,2,3'::text, '  select m from generate_series(1,2) m'::text) crosstab(am_id integer, "1" numeric, "2" numeric);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_honorarios_1_1(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_honorarios_1_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_honorarios_1_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_honorarios_1_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, fechaemision date, fechapago date, tipodocumento character varying, serie text, numero text, tipodoc character varying, numdoc character varying, partner character varying, divisa character varying, tipodecambio numeric, monto numeric, retencion numeric, neto numeric, state character varying, periodopago character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
  SELECT row_number() OVER () AS id,*
   FROM ( SELECT DISTINCT ap.name AS periodo,
            aj.code AS libro,
            am.name AS voucher,
            am.date AS fechaemision,
                CASE
                    WHEN ai.state::text = 'paid'::text THEN pago.date::date
                    ELSE ai.date_due::date
                END AS fechapago,
            itd.code AS tipodocumento,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN NULL::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, 0, "position"(am.dec_reg_nro_comprobante::text, '-'::text))
                END AS serie,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN am.dec_reg_nro_comprobante::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, "position"(am.dec_reg_nro_comprobante::text, '-'::text) + 1)
                END AS numero,
            itdp.code AS tipodoc,
            rp.type_number AS numdoc,
            rp.name AS partner,
            rc.name AS divisa,

            CASE WHEN $1 THEN am.com_det_type_change
            ELSE
            CASE WHEN rc.name = 'USD' THEN am.com_det_type_change ELSE Null::numeric END END AS tipodecambio,
            pr.monto,
            pr.retencion,
            pr.total AS neto,
            ai.state,
                CASE
                    WHEN ai.state::text = 'paid'::text THEN ap_pago.name
                    ELSE NULL::character varying
                END AS periodopago
           FROM ( SELECT vst_reg_forth_1_1.am_id,
                    sum(vst_reg_forth_1_1."1") AS monto,
                    sum(vst_reg_forth_1_1."2") AS retencion,
                    COALESCE(sum(vst_reg_forth_1_1."1"), 0::numeric) - abs(COALESCE(sum(vst_reg_forth_1_1."2"), 0::numeric)) AS total
                   FROM get_honorarios_1_1($1,$2,$3) as vst_reg_forth_1_1
                  GROUP BY vst_reg_forth_1_1.am_id) pr
             JOIN account_move am ON am.id = pr.am_id
             JOIN account_journal aj ON aj.id = am.journal_id
             JOIN account_period ap ON ap.id = am.period_id
             LEFT JOIN it_type_document itd ON itd.id = am.dec_reg_type_document_id
             LEFT JOIN res_partner rp ON rp.id = am.partner_id
             LEFT JOIN it_type_document_partner itdp ON itdp.id = rp.type_document_id
             LEFT JOIN res_currency rc ON rc.id = am.com_det_currency
             LEFT JOIN account_invoice ai ON ai.move_id = am.id
              LEFT JOIN account_perception adr ON adr.father_invoice_id = ai.id
             LEFT JOIN it_type_document itd2 ON itd2.id = am.dec_mod_type_document_id
             LEFT JOIN account_move_line pago ON pago.id = (( SELECT max(pagoc.id) AS max
                   FROM account_move amc
                     JOIN account_move_line amlc ON amlc.move_id = amc.id
                     JOIN account_move_line pagoc ON amlc.reconcile_id = pagoc.reconcile_id
                  WHERE amc.id = am.id AND amlc.id <> pagoc.id
                  GROUP BY am.id))
             LEFT JOIN account_period ap_pago ON ap_pago.id = pago.period_id
             CROSS JOIN main_parameter mp
             where am.state != 'draft'
          ORDER BY ap.name, aj.code, am.name) t;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_honorarios_1_1_1(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_kardex(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex(
    IN date_ini integer,
    IN date_end integer,
    IN integer[],
    IN integer[])
  RETURNS TABLE(almacen character varying, categoria character varying, name_template character varying, fecha date, periodo character varying, ctanalitica character varying, serial character varying, nro character varying, operation_type character varying, name character varying, ingreso numeric, salida numeric, saldof numeric, debit numeric, credit numeric, cadquiere numeric, saldov numeric, cprom numeric, type character varying, esingreso text, product_id integer, location_id integer, doc_type_ope character varying) AS
$BODY$  
BEGIN
return query select * from vst_kardex_sunat where fecha_num(vst_kardex_sunat.fecha) between $1 and $2 and vst_kardex_sunat.product_id = ANY($3) and vst_kardex_sunat.location_id = ANY($4);
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_kardex(integer, integer, integer[], integer[])
  OWNER TO openpg;



-- Function: public.get_kardex_fis(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex_fis(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex_fis(
    IN date_ini integer,
    IN date_end integer,
    IN integer[],
    IN integer[])
  RETURNS TABLE(almacen character varying, categoria character varying, name_template character varying, fecha date, periodo character varying, ctanalitica character varying, serial character varying, nro character varying, operation_type character varying, name character varying, ingreso numeric, salida numeric, saldof numeric, debit numeric, credit numeric, cadquiere numeric, saldov numeric, cprom numeric, type character varying, esingreso text, product_id integer, location_id integer, doc_type_ope character varying) AS
$BODY$  
BEGIN
return query select * from vst_kardex_fis_sunat where fecha_num(vst_kardex_fis_sunat.fecha) between $1 and $2 and vst_kardex_fis_sunat.product_id = ANY($3) and vst_kardex_fis_sunat.location_id = ANY($4);
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_kardex_fis(integer, integer, integer[], integer[])
  OWNER TO openpg;



-- Function: public.get_kardex_fis_sumi(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex_fis_sumi(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex_fis_sumi(
    IN date_ini integer,
    IN date_end integer,
    IN integer[],
    IN integer[])
  RETURNS TABLE(almacen character varying, categoria character varying, name_template character varying, fecha date, periodo character varying, ctanalitica character varying, serial character varying, nro character varying, operation_type character varying, name character varying, ingreso numeric, salida numeric, saldof numeric, debit numeric, credit numeric, cadquiere numeric, saldov numeric, cprom numeric, type character varying, esingreso text, product_id integer, location_id integer, doc_type_ope character varying) AS
$BODY$  
BEGIN
return query select * from vst_kardex_fissumi_sunat where fecha_num(vst_kardex_fis_sunat.fecha) between $1 and $2 and vst_kardex_fis_sunat.product_id = ANY($3) and vst_kardex_fis_sunat.location_id = ANY($4);
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_kardex_fis_sumi(integer, integer, integer[], integer[])
  OWNER TO openpg;




-- Function: public.get_kardex_v(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex_v(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex_v(
    IN date_ini integer,
    IN date_end integer,
    IN productos integer[],
    IN almacenes integer[],
    OUT almacen character varying,
    OUT categoria character varying,
    OUT name_template character varying,
    OUT fecha date,
    OUT periodo character varying,
    OUT ctanalitica character varying,
    OUT serial character varying,
    OUT nro character varying,
    OUT operation_type character varying,
    OUT name character varying,
    OUT ingreso numeric,
    OUT salida numeric,
    OUT saldof numeric,
    OUT debit numeric,
    OUT credit numeric,
    OUT cadquiere numeric,
    OUT saldov numeric,
    OUT cprom numeric,
    OUT type character varying,
    OUT esingreso text,
    OUT product_id integer,
    OUT location_id integer,
    OUT doc_type_ope character varying,
    OUT ubicacion_origen integer,
    OUT ubicacion_destino integer,
    OUT stock_moveid integer,
    OUT account_invoice character varying,
    OUT product_account character varying,
    OUT default_code character varying,
    OUT unidad character varying,
    OUT mrpname character varying,
    OUT ruc character varying,
    OUT comapnyname character varying,
    OUT cod_sunat character varying,
    OUT tipoprod character varying,
    OUT coduni character varying,
    OUT metodo character varying,
    OUT cu_entrada numeric,
    OUT cu_salida numeric,
    OUT period_name character varying,
    OUT stock_doc character varying,
    OUT origen character varying,
    OUT destino character varying,
    OUT type_doc character varying,
    OUT numdoc_cuadre character varying,
    OUT doc_partner character varying,
    OUT fecha_albaran date,
    OUT pedido_compra character varying,
    OUT licitacion character varying,
    OUT doc_almac character varying,
    OUT lote character varying)
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

  select res_partner.name,res_partner.type_number from res_company 
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


        

           ruc = h.type_number;
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
          if dr.serial is not null then 
            debit=coalesce(dr.debit,0);
          else
            if dr.ubicacion_origen=8 then
              debit =0;
            else
              debit = coalesce(dr.debit,0);
            end if;
          end if;
          

          
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
ALTER FUNCTION public.get_kardex_v(integer, integer, integer[], integer[])
  OWNER TO openpg;





-- Function: public.get_libro_diario(boolean, integer, integer)

-- DROP FUNCTION public.get_libro_diario(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_libro_diario(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, divisa character varying, tipodecambio numeric, importedivisa numeric, codigo character varying, partner character varying, tipodocumento character varying, numero character varying, fechaemision date, fechavencimiento date, glosa character varying, ctaanalitica character varying, refconcil character varying, statefiltro character varying, aml_id integer, aj_id integer, ap_id integer, am_id integer, aa_id integer, rc_id integer, rp_id integer, itd_id integer, aaa_id integer, state character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,*
   FROM ( SELECT ap.name AS periodo,
            aj.code AS libro,
            am.name AS voucher,
            aa.code AS cuenta,
            aa.name AS descripcion,
            CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
            CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
            rc.name AS divisa,
            CASE WHEN $1 THEN aml.currency_rate_it
            ELSE
            CASE WHEN rc.name ='USD' THEN aml.currency_rate_it ELSE Null::numeric END END AS tipodecambio,
            aml.amount_currency AS importedivisa,
            rp.type_number AS codigo,
            rp.name AS partner,
            itd.code AS tipodocumento,
            aml.nro_comprobante AS numero,
            aml.date AS fechaemision,
            aml.date_maturity AS fechavencimiento,
            aml.name AS glosa,
            aaa.name AS ctaanalitica,
            aml.reconcile_ref AS refconcil,
            am.state AS statefiltro,
            aml.id AS aml_id,
            aj.id AS aj_id,
            ap.id AS ap_id,
            am.id AS am_id,
            aa.id AS aa_id,
            rc.id AS rc_id,
            rp.id AS rp_id,
            itd.id AS itd_id,
            aaa.id AS aaa_id,
            case when am.state = 'posted'::varchar then 'Asentado'::varchar ELSE 'Borrador'::varchar END as state
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
             where am.state != 'draft'
          ORDER BY ap.id, aj.code, am.name) t
          where periodo_num(t.periodo) >= $2 and periodo_num(t.periodo)<=$3;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_libro_diario(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_libro_mayor(boolean, integer, integer)

-- DROP FUNCTION public.get_libro_mayor(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_libro_mayor(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, divisa character varying, tipocambio numeric, importedivisa numeric, conciliacion character varying, fechaemision date, fechavencimiento date, tipodocumento character varying, numero character varying, ruc character varying, partner character varying, glosa character varying, analitica character varying, ordenamiento integer, cuentaname character varying, aml_id integer, state character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,* from ( (SELECT ap.name AS periodo,
                    aj.code AS libro,
                    am.name AS voucher,
                    aa.code AS cuenta,
                    aa.name AS descripcion,
                    CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
      CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
                    rc.name AS divisa,

            CASE WHEN $1 THEN aml.currency_rate_it
            ELSE
                    CASE WHEN rc.name = 'USD' THEN aml.currency_rate_it ELSE Null::numeric END END AS tipocambio,
                    aml.amount_currency AS importedivisa,
                    aml.reconcile_ref AS conciliacion,
                    aml.date AS fechaemision,
                    aml.date_maturity AS fechavencimiento,
                    itd.code AS tipodocumento,
                    aml.nro_comprobante AS numero,
                    rp.type_number AS ruc,
                    rp.name AS partner,
                    aml.name AS glosa,
                    aaa.code AS analitica,
                    1 AS ordenamiento,
                        CASE
                            WHEN "position"(aa.name::varchar, '-'::varchar) = 0 THEN aa.name::varchar
                            ELSE "substring"(aa.name::varchar, 0, "position"(aa.name::varchar, '-'::varchar))::varchar
                        END AS cuentaname,
                    aml.id as aml_id,
                    case when am.state = 'draft' then 'Borrador'::varchar else 'Asentado'::varchar END as state
                   FROM account_move_line aml
                     JOIN account_journal aj ON aml.journal_id = aj.id
                     JOIN account_move am ON aml.move_id = am.id
                     JOIN account_account aa ON aml.account_id = aa.id
                     JOIN account_period ap ON ap.id = aml.period_id
                     LEFT JOIN res_currency rc ON aml.currency_id = rc.id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
                     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
                     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
                   WHERE periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
                   and am.state != 'draft')
  
                  UNION ALL
                  (
    SELECT  
      periodo_string($2) as periodo,  
      Null::varchar as libro,
      Null::varchar as voucher, 
      aa.code as Cuenta, 
      aa.name as descripcion,
       CASE WHEN $1 THEN (CASE WHEN sum(aml.debit_me) - sum(aml.credit_me) >0 THEN sum(aml.debit_me) - sum(aml.credit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN sum(aml.debit) - sum(aml.credit) ELSE 0 END) END AS debe,
      CASE WHEN $1 THEN (CASE WHEN sum(aml.credit_me) - sum(aml.debit_me) >0 THEN sum(aml.credit_me) - sum(aml.debit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.credit) - sum(aml.debit) >0 THEN sum(aml.credit) - sum(aml.debit) ELSE 0 END) END AS haber,
    
       Null::varchar as divisa,
       Null::numeric as tipocambio,
       Null::numeric as importedivisa,
       Null::varchar as conciliacion,
       Null::date as fechaemision,
       Null::date as fechavencimiento,
       Null::varchar as tipodocumento,
       Null::varchar as numero,
       Null::varchar as ruc,
       Null::varchar as partner,
       'Saldo Inicial'::varchar as glosa,
       Null::varchar as analitica,
       0 as ordenamiento,
       Null::varchar as cuentaname,
       Null::integer as aml_id,
       'Asentado'::varchar as state
    FROM
      account_move_line aml
      INNER JOIN account_journal aj ON (aml.journal_id = aj.id)
      INNER JOIN account_move am ON (aml.move_id = am.id)
      INNER JOIN account_account aa ON (aml.account_id = aa.id)
      INNER JOIN account_period ap_1 ON (ap_1.id = aml.period_id)
      LEFT OUTER JOIN res_currency rc ON (aml.currency_id = rc.id)
      LEFT OUTER JOIN res_partner rp ON (rp.id = aml.partner_id)
      LEFT OUTER JOIN account_analytic_account aaa ON (aaa.id = aml.analytic_account_id)
    WHERE periodo_num(ap_1.name) < $2 
    and am.state != 'draft'
    group by aa.code, aa.name) 
    order by cuenta,ordenamiento,periodo,fechaemision) AS T; 

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_libro_mayor(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_max_min(integer, character varying, character varying, character varying, integer[])

-- DROP FUNCTION public.get_max_min(integer, character varying, character varying, character varying, integer[]);

CREATE OR REPLACE FUNCTION public.get_max_min(
    IN rotacion integer,
    IN evaluacion character varying,
    IN fr_str character varying,
    IN td_str character varying,
    IN wh_id integer[])
  RETURNS TABLE(product_id integer, uom_id integer, category character varying, rotation numeric, saldo numeric, minimo numeric, maximo numeric, reponer numeric, sobrante numeric, abastecimiento numeric) AS
$BODY$

BEGIN
RETURN QUERY

select
    pp.id as product_id,
    pt.uom_id as uom_id,
     pc.name as category,

    (case when swo.estimated_rotation > 0 then swo.estimated_rotation else coalesce((select * from get_rotation(pp.id, $3, $4)),0) end) as rotation,

     coalesce((select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss ),0) as saldo,
     (case when swo.max_min > 0 then coalesce(swo.product_min_qty,0)/swo.max_min*$1 else coalesce(swo.product_min_qty,0) end) as minimo,
     (case when swo.max_min > 0 then coalesce(swo.product_max_qty,0)/swo.max_min*$1 else coalesce(swo.product_max_qty,0) end) as maximo,

     (case
        when ($2 = 'faltantes')
        then (case when swo.max_min > 0 then coalesce(swo.product_max_qty,0)/swo.max_min*$1 else coalesce(swo.product_max_qty,0) end) - (select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss where rss.product_id = pp.id)
        else 0 end) as reponer,

    (case
        when ($2 = 'sobrantes')
        then (select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss where rss.product_id = pp.id) - (case when swo.max_min > 0 then coalesce(swo.product_max_qty,0)/swo.max_min*$1 else coalesce(swo.product_max_qty,0) end)
        else 0 end) as sobrante,

    (case
        when coalesce((select * from get_rotation(pp.id, $3, $4)),0) != 0 and $1 != 0
        then round((select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss where rss.product_id = pp.id)/( (case when swo.estimated_rotation > 0 then swo.estimated_rotation else coalesce((select * from get_rotation(pp.id, $3, $4)),0) end) / $1))
        else 0 end) as abastecimiento
     
from product_product pp
left join product_template pt on pp.product_tmpl_id = pt.id
left join product_category pc on pt.categ_id = pc.id
left join product_uom pu on pt.uom_id = pu.id
left join stock_warehouse_orderpoint swo on swo.product_id = pp.id
where pt.type != 'consu';

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_max_min(integer, character varying, character varying, character varying, integer[])
  OWNER TO openpg;




-- Function: public.get_moves_cost(integer, integer, integer[], integer[], character varying, character varying)

-- DROP FUNCTION public.get_moves_cost(integer, integer, integer[], integer[], character varying, character varying);

CREATE OR REPLACE FUNCTION public.get_moves_cost(
    IN integer,
    IN integer,
    IN integer[],
    IN integer[],
    IN character varying,
    IN character varying)
  RETURNS TABLE(out_account character varying, valued_account character varying, analytic_account character varying, producto integer, saldov numeric, category character varying) AS
$BODY$
BEGIN
    RETURN QUERY
    select 
    ip1.value_reference as out_account,
    ip2.value_reference as valued_account,
    result.ctanalitica as analytic_account,
    result.product_id as producto, 
    result.saldov as saldov,
    pc.name as category
    from (
    (select * from get_kardex_v($1,$2,$3,$4)) as result
    join stock_location sl on sl.id = result.ubicacion_origen and sl.usage = $5
    join stock_location sl2 on sl2.id = result.ubicacion_destino and sl2.usage = $6
    left join product_product pp on pp.id = result.product_id
    left join product_template pt on pt.id = pp.product_tmpl_id
    left join product_category pc on pt.categ_id = pc.id 
    left join ir_property ip1 on (ip1.res_id = 'product.category,' || pc.id) and ip1.name = 'property_stock_account_output_categ' 
    left join ir_property ip2 on (ip2.res_id = 'product.category,' || pc.id) and ip2.name = 'property_stock_valuation_account_id' )
    order by producto, saldov;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_moves_cost(integer, integer, integer[], integer[], character varying, character varying)
  OWNER TO openpg;




-- Function: public.get_periodo_libro(character varying)

-- DROP FUNCTION public.get_periodo_libro(character varying);

CREATE OR REPLACE FUNCTION public.get_periodo_libro(IN libro character varying)
  RETURNS TABLE(name character varying, periodo_num integer) AS
$BODY$
    Select distinct name,periodo_num(name) from account_period order by periodo_num(name)
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_periodo_libro(character varying)
  OWNER TO openpg;



-- Function: public.get_report_bank_with_saldoinicial(boolean, integer, integer)

-- DROP FUNCTION public.get_report_bank_with_saldoinicial(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_report_bank_with_saldoinicial(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, fecha date, cheque character varying, nombre character varying, documento character varying, glosa character varying, cargo_mn numeric, abono_mn numeric, tipo_cambio numeric, cargo_me numeric, abono_me numeric, nro_asiento integer, aa_id integer, ordenamiento integer, diario_id integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,*
   FROM ( SELECT * from(
    SELECT 
    aml.date AS fecha,
    aml.nro_comprobante AS cheque,
    rp.name as nombre,

    am.name as documento,
    
    aml.name as glosa,
    aml.debit as cargo_mn,
    aml.credit as abono_mn,
    aml.currency_rate_it as tipo_cambio,
    CASE WHEN aml.amount_currency>0 THEN aml.amount_currency ELSE 0 END as cargo_me,
    CASE WHEN aml.amount_currency<0 THEN -1*aml.amount_currency ELSE 0 END as abono_me,
    am.id as nro_asiento,
    aa.id as aa_id,
    1 as ordenamiento,
    aj.id as diario_id


    FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
     JOIN account_account aa ON aa.id = aml.account_id
     LEFT JOIN it_means_payment mp ON mp.id = aml.means_payment_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
     LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
  and am.state != 'draft'
  
UNION ALL

SELECT 
    Null::date AS fecha,
    Null::varchar AS cheque,
    Null::varchar AS nombre,
    Null::varchar as documento,
    'Saldo Inicial' as glosa,
    sum(aml.debit) as cargo_mn,   
    sum(aml.credit) as abono_mn,
    Null::numeric as tipo_cambio,
    
    sum( CASE WHEN aml.amount_currency>0 THEN aml.amount_currency else 0 END ) as cargo_me,
    sum( CASE WHEN aml.amount_currency<0 THEN -1* aml.amount_currency ELSE 0 END) as abono_me,
    Null::integer as nro_asiento,
    aa.id as aa_id,
    0 as ordenamiento,
    0 as diario_id

    FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
     JOIN account_account aa ON aa.id = aml.account_id
     LEFT JOIN it_means_payment mp ON mp.id = aml.means_payment_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
     LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE periodo_num(ap.name) >= (substring($2::varchar,0,5)||'0')::integer  and periodo_num(ap.name) < $2
  and am.state != 'draft'
  group by aa.id


  ) AS T
  order by ordenamiento,fecha,cheque,documento
  
  ) AS M;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_report_bank_with_saldoinicial(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_reporte_hoja_balance(boolean, integer, integer)

-- DROP FUNCTION public.get_reporte_hoja_balance(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_reporte_hoja_balance(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric, cuentaf character varying, totaldebe numeric, totalhaber numeric, finaldeudor numeric, finalacreedor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select X.id,X.cuenta,X.descripcion,X.debe,X.haber,X.saldodeudor,X.saldoacredor,
CASE WHEN ((X.activo >0 or X.pasivo >0) or (X.ver_pas=1) ) and X.finaldeudor>0 THEN X.finaldeudor ELSE 0 end activo,
CASE WHEN ((X.pasivo >0 or X.activo >0) or (X.ver_pas=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end pasivo,
CASE WHEN ((X.perdidasnat >0 or X.ganancianat >0) or (X.ver_nat=1) ) and X.finaldeudor>0 THEN X.finaldeudor  ELSE 0 end perdidasnat,
CASE WHEN ((X.ganancianat >0 or X.perdidasnat >0) or (X.ver_nat=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end ganancianat,
CASE WHEN ((X.perdidasfun >0 or X.gananciafun >0) or (X.ver_fun=1) ) and X.finaldeudor >0 THEN X.finaldeudor ELSE 0 end perdidasfun,
CASE WHEN ((X.gananciafun >0 or X.perdidasfun >0) or (X.ver_fun=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end gananciafun,
X.cuentaf,X.totaldebe,X.totalhaber,X.finaldeudor,X.finalacreedor

 from (select row_number() OVER () AS id,RES.* from 
  (select  CASE WHEN M.cuenta IS NOT NULL THEN M.cuenta ELSE aa_f.code END as cuenta, CASE WHEN M.descripcion IS NOT NULL THEN M.descripcion ELSE aa_f.name END as descripcion, M.debe, M.haber, M.saldodeudor, M.saldoacredor, M.activo, M.pasivo, M.perdidasnat, M.ganancianat, M.perdidasfun, M.gananciafun,T.cuentaF, T.totaldebe,T.totalhaber ,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) >0 THEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) ELSE 0 END as finaldeudor,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) <0 THEN -1 * (coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0)) ELSE 0 END as finalacreedor,
T.ver_pas, T.ver_nat, T.ver_fun
from get_hoja_trabajo_detalle_balance($1,(substring($2::varchar,0,5)||'01')::integer,$3) AS M 
FULL JOIN (select O1.cuenta as cuentaF,
--sum(O1.saldodeudor) as totaldebe,
--sum(O1.saldoacredor) as totalhaber   from get_hoja_trabajo_detalle_balance($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
sum(O1.debe) as totaldebe,
sum(O1.haber) as totalhaber,
CASE WHEN sum(O1.activo)> 0 or sum(O1.pasivo) >0 THEN 1 ELSE 0 END as ver_pas,
CASE WHEN sum(O1.perdidasnat)> 0 or sum(O1.ganancianat) >0 THEN 1 ELSE 0 END as ver_nat,
CASE WHEN sum(O1.perdidasfun)> 0 or sum(O1.gananciafun) >0 THEN 1 ELSE 0 END as ver_fun
   from get_hoja_trabajo_detalle_balance($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
group by O1.cuenta) AS T on T.cuentaF = M.cuenta
left join account_account aa_f on aa_f.code = T.cuentaF order by cuenta) RES ) AS X;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_reporte_hoja_balance(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_reporte_hoja_registro(boolean, integer, integer)

-- DROP FUNCTION public.get_reporte_hoja_registro(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_reporte_hoja_registro(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric, cuentaf character varying, totaldebe numeric, totalhaber numeric, finaldeudor numeric, finalacreedor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select X.id,X.cuenta,X.descripcion,X.debe,X.haber,X.saldodeudor,X.saldoacredor,
CASE WHEN ((X.activo >0 or X.pasivo >0) or (X.ver_pas=1) ) and X.finaldeudor>0 THEN X.finaldeudor ELSE 0 end activo,
CASE WHEN ((X.pasivo >0 or X.activo >0) or (X.ver_pas=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end pasivo,
CASE WHEN ((X.perdidasnat >0 or X.ganancianat >0) or (X.ver_nat=1) ) and X.finaldeudor>0 THEN X.finaldeudor  ELSE 0 end perdidasnat,
CASE WHEN ((X.ganancianat >0 or X.perdidasnat >0) or (X.ver_nat=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end ganancianat,
CASE WHEN ((X.perdidasfun >0 or X.gananciafun >0) or (X.ver_fun=1) ) and X.finaldeudor >0 THEN X.finaldeudor ELSE 0 end perdidasfun,
CASE WHEN ((X.gananciafun >0 or X.perdidasfun >0) or (X.ver_fun=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end gananciafun,
X.cuentaf,X.totaldebe,X.totalhaber,X.finaldeudor,X.finalacreedor

 from (select row_number() OVER () AS id,RES.* from 
  (select  CASE WHEN M.cuenta IS NOT NULL THEN M.cuenta ELSE aa_f.code END as cuenta, CASE WHEN M.descripcion IS NOT NULL THEN M.descripcion ELSE aa_f.name END as descripcion, M.debe, M.haber, M.saldodeudor, M.saldoacredor, M.activo, M.pasivo, M.perdidasnat, M.ganancianat, M.perdidasfun, M.gananciafun,T.cuentaF, T.totaldebe,T.totalhaber ,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) >0 THEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) ELSE 0 END as finaldeudor,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) <0 THEN -1 * (coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0)) ELSE 0 END as finalacreedor,
T.ver_pas, T.ver_nat, T.ver_fun
from get_hoja_trabajo_detalle_registro($1,(substring($2::varchar,0,5)||'01')::integer,$3) AS M 
FULL JOIN (select O1.cuenta as cuentaF,
--sum(O1.saldodeudor) as totaldebe,
--sum(O1.saldoacredor) as totalhaber   from get_hoja_trabajo_detalle_registro($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
sum(O1.debe) as totaldebe,
sum(O1.haber) as totalhaber,
CASE WHEN sum(O1.activo)> 0 or sum(O1.pasivo) >0 THEN 1 ELSE 0 END as ver_pas,
CASE WHEN sum(O1.perdidasnat)> 0 or sum(O1.ganancianat) >0 THEN 1 ELSE 0 END as ver_nat,
CASE WHEN sum(O1.perdidasfun)> 0 or sum(O1.gananciafun) >0 THEN 1 ELSE 0 END as ver_fun

   from get_hoja_trabajo_detalle_registro($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
group by O1.cuenta) AS T on T.cuentaF = M.cuenta 
left join account_account aa_f on aa_f.code = T.cuentaF order by cuenta) RES) AS X;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_reporte_hoja_registro(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_rotation(integer, character varying, character varying)

-- DROP FUNCTION public.get_rotation(integer, character varying, character varying);

CREATE OR REPLACE FUNCTION public.get_rotation(
    producto integer,
    rd character varying,
    td character varying)
  RETURNS SETOF numeric AS
$BODY$
BEGIN
RETURN QUERY
    select sum(sm.product_qty)
     from stock_move sm
     left join stock_picking sp on sm.picking_id = sp.id
     left join stock_picking_type spt on sp.picking_type_id = spt.id
     left join stock_location sls on spt.default_location_src_id = sls.id
     left join stock_location sld on spt.default_location_dest_id = sld.id
     where
         sm.product_id = $1 and
         sls.usage = 'internal' and
         fecha_num(sm.date::date) between fecha_num($2::date) and fecha_num($3::date);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_rotation(integer, character varying, character varying)
  OWNER TO openpg;





-- Function: public.get_balance_general(boolean, integer, integer)

-- DROP FUNCTION public.get_balance_general(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_balance_general(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(name character varying, grupo character varying, saldo numeric, orden integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select aat.name  , aat.group_balance,
CASE WHEN $1= false THEN
  (CASE WHEN aat.group_balance = 'B1' OR aat.group_balance = 'B2' THEN  sum(aml.debit)-sum(aml.credit) 
   ELSE sum(aml.credit)-sum(aml.debit)  END )
  --sum(aml.debit)-sum(aml.credit) 
ELSE
  (CASE WHEN aat.group_balance = 'B1' OR aat.group_balance = 'B2' THEN  sum(aml.debit_me)-sum(aml.credit_me) 
  ELSE sum(aml.credit_me)-sum(aml.debit_me)  END )
  --sum(aml.debit_me)-sum(aml.credit_me) 
END as saldo, aat.order_balance
from account_account aca
inner join account_account_type aat on aat.id = aca.user_type

inner join account_move_line aml on aml.account_id = aca.id
inner join account_move am on am.id = aml.move_id
inner join account_period ap on ap.id = aml.period_id
where periodo_num(ap.name) >= $2 and  periodo_num(ap.name) <= $3 and aat.group_balance IS NOT NULL
and am.state != 'draft'
group by aat.name, aat.group_balance, aat.order_balance
order by aat.order_balance,aat.name;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_balance_general(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_cajabanco_with_saldoinicial(boolean, integer, integer)

-- DROP FUNCTION public.get_cajabanco_with_saldoinicial(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_cajabanco_with_saldoinicial(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, cuentacode character varying, cuentaname character varying, debe numeric, haber numeric, divisa character varying, tipodecambio numeric, importedivisa numeric, codigo character varying, partner character varying, tipodocumento character varying, numero character varying, fechaemision date, fechavencimiento date, glosa character varying, ctaanalitica character varying, refconcil character varying, statefiltro character varying, mediopago character varying, ordenamiento integer, entfinan character varying, nrocta character varying, moneda character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,*
   FROM ( SELECT * from(
    SELECT ap.name AS periodo,
    aj.code AS libro,
    am.name AS voucher,
    aa.code AS cuentacode,
    aa.name AS cuentaname,
    CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
    CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
    rc.name AS divisa,

            CASE WHEN $1 THEN aml.currency_rate_it
            ELSE
    CASE WHEN rc.name ='USD' THEN aml.currency_rate_it ELSE Null::numeric END END AS tipodecambio,
    aml.amount_currency AS importedivisa,
    rp.type_number AS codigo,
    rp.name AS partner,
    itd.description AS tipodocumento,
    aml.nro_comprobante AS numero,
    aml.date AS fechaemision,
    aml.date_maturity AS fechavencimiento,
    aml.name AS glosa,
    aaa.name AS ctaanalitica,
    aml.reconcile_ref AS refconcil,
    am.state AS statefiltro,
    mp.code AS mediopago,
    1 AS ordenamiento,
    aa.cashbank_financy AS entfinan,
    aa.cashbank_number AS nrocta,
    COALESCE(rc.name, ( SELECT rc_1.name
     FROM res_company
       JOIN res_currency rc_1 ON rc_1.id = res_company.currency_id)) AS moneda
FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
  JOIN account_account aa ON aa.id = aml.account_id
         LEFT JOIN it_means_payment mp ON mp.id = aml.means_payment_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
                     LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE aa.type::text = 'liquidity'::text and periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
  and am.state != 'draft'
  
UNION ALL

SELECT periodo_string($2) AS periodo,
    Null::varchar AS libro,
    Null::varchar AS voucher,
    aa.code AS cuentacode,
    aa.name AS cuentaname,
    CASE WHEN $1 THEN (CASE WHEN sum(aml.debit_me) - sum(aml.credit_me) >0 THEN sum(aml.debit_me) - sum(aml.credit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN sum(aml.debit) - sum(aml.credit) ELSE 0 END) END AS debe,
    CASE WHEN $1 THEN (CASE WHEN sum(aml.credit_me) - sum(aml.debit_me) >0 THEN sum(aml.credit_me) - sum(aml.debit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.credit) - sum(aml.debit) >0 THEN sum(aml.credit) - sum(aml.debit) ELSE 0 END) END AS haber,
    Null::varchar AS divisa,
    Null::numeric AS tipodecambio,
    Null::numeric AS importedivisa,
    Null::varchar AS codigo,
    Null::varchar AS partner,
    Null::varchar AS tipodocumento,
    Null::varchar AS numero,
    Null::date AS fechaemision,
    Null::date AS fechavencimiento,
    'Saldo Inicial'::varchar AS glosa,
    Null::varchar AS ctaanalitica,
    Null::varchar AS refconcil,
    Null::varchar AS statefiltro,
    Null::varchar AS mediopago,
    0 AS ordenamiento,
    Null::varchar AS entfinan,
    Null::varchar AS nrocta,
    Null::varchar AS moneda
   FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
     JOIN account_account aa ON aa.id = aml.account_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE aa.type::text = 'liquidity'::text and periodo_num(ap.name) < $2
  and am.state != 'draft'
  group by aa.code, aa.name


  ) AS T
  order by cuentacode,ordenamiento, fechaemision
  
  ) AS M;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_cajabanco_with_saldoinicial(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_compra_1(boolean, integer, integer)

-- DROP FUNCTION public.get_compra_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_compra_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(comprobante character varying, am_id integer, clasifica character varying, base_impuesto numeric, monto numeric, record_shop character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
   SELECT account_move.dec_reg_nro_comprobante AS comprobante,
    account_move.id AS am_id,
    account_tax_code.name AS clasifica,
    CASE WHEN $1 THEN 
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END ) ELSE account_move_line.tax_amount END AS base_impuesto,
    CASE WHEN $1 THEN 
  (CASE
            WHEN account_journal.type::text = 'purchase_refund'::text THEN account_move_line.currency_rate_it*account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.currency_rate_it*account_move_line.tax_amount
        END)
    ELSE
        (CASE
            WHEN account_journal.type::text = 'purchase_refund'::text THEN account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.tax_amount
        END)
       END AS monto,
    account_tax_code.record_shop
   FROM account_move
     JOIN account_move_line ON account_move.id = account_move_line.move_id
     JOIN account_journal ON account_move_line.journal_id = account_journal.id AND account_move.journal_id = account_journal.id
     JOIN account_period ON account_move.period_id = account_period.id AND account_move.period_id = account_period.id
     LEFT JOIN it_type_document ON account_move_line.type_document_id = it_type_document.id AND account_move.dec_mod_type_document_id = it_type_document.id AND account_move.dec_reg_type_document_id = it_type_document.id
     LEFT JOIN res_partner ON account_move.partner_id = res_partner.id AND account_move_line.partner_id = res_partner.id
     LEFT JOIN it_type_document_partner ON res_partner.type_document_id = it_type_document_partner.id
     JOIN account_tax_code ON account_move_line.tax_code_id = account_tax_code.id
  WHERE account_journal.register_sunat::text = '1'::text and periodo_num(account_period.name) >= $2 and periodo_num(account_period.name) <= $3
  and account_move.state != 'draft'
  ORDER BY account_move.dec_reg_nro_comprobante;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_compra_1(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_compra_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_compra_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_compra_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(am_id integer, "1" numeric, "2" numeric, "3" numeric, "4" numeric, "5" numeric, "6" numeric, "7" numeric, "8" numeric, "9" numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 

  SELECT crosstab.am_id,
    crosstab."1",
    crosstab."2",
    crosstab."3",
    crosstab."4",
    crosstab."5",
    crosstab."6",
    crosstab."7",
    crosstab."8",
    crosstab."9"
   FROM crosstab('SELECT c1.am_id ,c1.record_shop,
  sum(c1.monto) as monto FROM get_compra_1(' || $1 || ',' || $2 || ','|| $3 || ') as c1
  GROUP BY c1.am_id, c1.record_shop
  ORDER BY 1,2,3'::text, '  select m from generate_series(1,9) m'::text) crosstab(am_id integer, "1" numeric, "2" numeric, "3" numeric, "4" numeric, "5" numeric, "6" numeric, "7" numeric, "8" numeric, "9" numeric);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_compra_1_1(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_compra_1_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_compra_1_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_compra_1_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, am_id integer, periodo character varying, libro character varying, voucher character varying, fechaemision date, fechavencimiento date, tipodocumento character varying, serie text, numero text, tdp character varying, ruc character varying, razonsocial character varying, bioge numeric, biogeng numeric, biong numeric, cng numeric, isc numeric, igva numeric, igvb numeric, igvc numeric, otros numeric, total numeric, comprobante character varying, moneda character varying, tc numeric, fechad date, numerod character varying, fechadm date, td character varying, anio character varying, seried text, numerodd text) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.am_id,
    t.periodo,
    t.libro,
    t.voucher,
    t.fechaemision,
    t.fechavencimiento,
    t.tipodocumento,
    t.serie,
    t.numero,
    t.tdp,
    t.ruc,
    t.razonsocial,
    t.bioge,
    t.biogeng,
    t.biong,
    t.cng,
    t.isc,
    t.igva,
    t.igvb,
    t.igvc,
    t.otros,
    t.total,
    t.comprobantenrodomicilio,
    t.moneda,
    t.tc,
    t.fechad,
    t.numerod,
    t.fechadm,
    t.td,
    t.anio,
    t.seried,
    t.numerodd
   FROM ( SELECT pr.am_id,
            round(pr.bioge, 2) AS bioge,
            round(pr.biogeng, 2) AS biogeng,
            round(pr.biong, 2) AS biong,
            round(pr.cng, 2) AS cng,
            round(pr.isc, 2) AS isc,
            round(pr.otros, 2) AS otros,
            round(pr.igva, 2) AS igva,
            round(pr.igvb, 2) AS igvb,
            round(pr.igvc, 2) AS igvc,
            round(pr.total, 2) AS total,
                CASE
                    WHEN itd.id = mp.no_home_document_id OR itd.id = mp.no_home_debit_document_id OR itd.id = mp.no_home_credit_document_id THEN am.dec_reg_nro_comprobante
                    ELSE NULL::character varying
                END AS comprobantenrodomicilio,
            aj.code AS libro,
            ap.name AS periodo,
            am.name AS voucher,
            am.date AS fechaemision,
            am.com_det_date_maturity AS fechavencimiento,
            itd.code AS tipodocumento,
                CASE
                    WHEN itd.id = mp.no_home_document_id OR itd.id = mp.no_home_debit_document_id OR itd.id = mp.no_home_credit_document_id THEN NULL::text
                    ELSE
                    CASE
                        WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN NULL::text
                        ELSE "substring"(am.dec_reg_nro_comprobante::text, 0, "position"(am.dec_reg_nro_comprobante::text, '-'::text))
                    END
                END AS serie,
                CASE
                    WHEN itd.id = mp.no_home_document_id OR itd.id = mp.no_home_debit_document_id OR itd.id = mp.no_home_credit_document_id THEN NULL::text
                    ELSE
                    CASE
                        WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN am.dec_reg_nro_comprobante::text
                        ELSE "substring"(am.dec_reg_nro_comprobante::text, "position"(am.dec_reg_nro_comprobante::text, '-'::text) + 1)
                    END
                END AS numero,
            itdp.code AS tdp,
            rp.type_number AS ruc,
            rp.name AS razonsocial,
            rc.name AS moneda,

            CASE WHEN $1 THEN round(am.com_det_type_change, 3)
            ELSE
            CASE WHEN rc.name = 'USD' THEN round(am.com_det_type_change, 3) ELSE Null::numeric END END AS tc,
            am.com_det_date AS fechad,
            am.com_det_number AS numerod,
            apercep.fecha AS fechadm,
            itd2.code AS td,
                CASE
                    WHEN itd.id = mp.export_document_id THEN date_part('year'::text, am.date)::character varying(50)
                    ELSE NULL::character varying(50)
                END AS anio,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN ''::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, 0, "position"(am.dec_mod_nro_comprobante::text, '-'::text))
                END AS seried,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN am.dec_mod_nro_comprobante::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, "position"(am.dec_mod_nro_comprobante::text, '-'::text) + 1)
                END AS numerodd
           FROM ( SELECT vst_reg_compras_1_1.am_id,
                    sum(vst_reg_compras_1_1."1") AS bioge,
                    sum(vst_reg_compras_1_1."2") AS biogeng,
                    sum(vst_reg_compras_1_1."3") AS biong,
                    sum(vst_reg_compras_1_1."4") AS cng,
                    sum(vst_reg_compras_1_1."5") AS isc,
                    sum(vst_reg_compras_1_1."6") AS otros,
                    sum(vst_reg_compras_1_1."7") AS igva,
                    sum(vst_reg_compras_1_1."8") AS igvb,
                    sum(vst_reg_compras_1_1."9") AS igvc,
                    COALESCE(sum(vst_reg_compras_1_1."1"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."2"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."3"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."4"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."5"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."6"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."7"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."8"), 0::numeric) + COALESCE(sum(vst_reg_compras_1_1."9"), 0::numeric) AS total
                   FROM get_compra_1_1($1,$2,$3) as vst_reg_compras_1_1
                  GROUP BY vst_reg_compras_1_1.am_id) pr
             JOIN account_move am ON am.id = pr.am_id
             JOIN account_journal aj ON aj.id = am.journal_id
             JOIN account_period ap ON ap.id = am.period_id
             LEFT JOIN it_type_document itd ON itd.id = am.dec_reg_type_document_id
             LEFT JOIN res_partner rp ON rp.id = am.partner_id
             LEFT JOIN it_type_document_partner itdp ON itdp.id = rp.type_document_id
             LEFT JOIN res_currency rc ON rc.id = am.com_det_currency
             LEFT JOIN account_invoice ai ON ai.move_id = am.id
             LEFT JOIN account_perception apercep ON apercep.father_invoice_id = ai.id
             LEFT JOIN account_invoice ai_hijo ON ai_hijo.supplier_invoice_number = apercep.comprobante and ai.type = ai_hijo.type
             LEFT JOIN it_type_document itd2 ON itd2.id = am.dec_mod_type_document_id
             CROSS JOIN main_parameter mp
          WHERE (apercep.id IN ( SELECT min(adr_1.id) AS min
                   FROM account_move am_1
                     JOIN account_invoice ai_1 ON ai_1.move_id = am_1.id
                     JOIN account_perception adr_1 ON adr_1.father_invoice_id = ai_1.id
                     JOIN account_invoice ai_hijo_1 ON ai_hijo_1.supplier_invoice_number = adr_1.comprobante and ai_1.type = ai_hijo_1.type
                  GROUP BY ai_1.id)) OR ai_hijo.* IS NULL
          ORDER BY ap.name, aj.code, am.name) t;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_compra_1_1_1(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_estado_funcion(boolean, integer, integer)

-- DROP FUNCTION public.get_estado_funcion(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_estado_funcion(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(name character varying, grupo character varying, saldo numeric, orden integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select aat.name , aat.group_function,
CASE WHEN $1= false THEN
   ((sum(aml.credit)-sum(aml.debit))   )
  --((sum(aml.debit)-sum(aml.credit))   )
ELSE
   ( (sum(aml.credit_me)-sum(aml.debit_me))   )
  --( (sum(aml.debit_me)-sum(aml.credit_me))   )
END as saldo, aat.order_function
from account_account aa
inner join account_account_type aat on aat.id = aa.user_type
inner join account_move_line aml on aml.account_id = aa.id
inner join account_move am on am.id = aml.move_id
inner join account_period ap on ap.id = aml.period_id
where periodo_num(ap.name) >= $2 and  periodo_num(ap.name) <= $3 and aat.group_function IS NOT NULL
and am.state != 'draft'
group by aat.name, aat.group_function, aat.order_function
order by aat.order_function,aat.name;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_estado_funcion(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_estado_nature(boolean, integer, integer)

-- DROP FUNCTION public.get_estado_nature(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_estado_nature(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(name character varying, grupo character varying, saldo numeric, orden integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select aat.name , aat.group_nature,
CASE WHEN $1= false THEN
  ((sum(aml.credit)-sum(aml.debit)) )
  --((sum(aml.debit)-sum(aml.credit)) )
ELSE
   ( (sum(aml.credit_me)-sum(aml.debit_me))  )
  --( (sum(aml.debit_me)-sum(aml.credit_me))  )
END as saldo, aat.order_nature
from account_account aa

inner join account_account_type aat on aat.id = aa.user_type
inner join account_move_line aml on aml.account_id = aa.id
inner join account_move am on am.id = aml.move_id
inner join account_period ap on ap.id = aml.period_id
where periodo_num(ap.name) >= $2 and  periodo_num(ap.name) <= $3 and aat.group_nature IS NOT NULL
and am.state != 'draft'
group by aat.name, aat.group_nature, aat.order_nature
order by aat.order_nature,aat.name;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_estado_nature(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_flujo_efectivo(boolean, integer, integer, integer)

-- DROP FUNCTION public.get_flujo_efectivo(boolean, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.get_flujo_efectivo(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer,
    IN period_saldo_inicial integer)
  RETURNS TABLE(periodo character varying, code character varying, concept character varying, debe numeric, haber numeric, saldo numeric, orden integer, grupo character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
$3 := $2;
END IF;

RETURN QUERY

(
select
periodo_string($4), ' '::varchar as code,'Saldo Inicial' as concept,
CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END as debe,
CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END as haber,
CASE WHEN $1 THEN sum(aml.debit_me)- sum(aml.credit_me) ELSE sum(aml.debit)- sum(aml.credit) END as saldo,
-1 as orden, 'E7'::varchar as "group"
from account_move_line aml
inner join account_move am on am.id = aml.move_id
inner join account_account aa on aa.id = aml.account_id
inner join account_period ap on ap.id = am.period_id
where aa.code like '10%' and periodo_num(ap.name)>=(substring($4::varchar,1,4) || '00' )::numeric and periodo_num(ap.name)<=$4
and am.state != 'draft'
)
UNION ALL
(
select
ap.name, ace.code,ace.concept,
CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END as debe,
CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END as haber,
CASE WHEN $1 THEN sum(aml.credit_me)- sum(aml.debit_me) ELSE sum(aml.credit)- sum(aml.debit) END as saldo,
ace.order as orden, ace."group"
from account_move_line aml
inner join account_move am on am.id = aml.move_id
inner join account_account aa on aa.id = aml.account_id
inner join account_config_efective ace on ace.id = aa.fefectivo_id
inner join account_period ap on ap.id = am.period_id
where aa.fefectivo_id is not null and periodo_num(ap.name)>=$2 and periodo_num(ap.name)<=$3
and am.state != 'draft' and am.id in ( select distinct am.id from account_move am inner join account_move_line aml on aml.move_id = am.id inner join account_account aa on aa.id = aml.account_id where aa.code like '10%' )
group by ap.name,ace.code , ace.concept, ace.order, ace."group"
order by ace.order);

END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_flujo_efectivo(boolean, integer, integer, integer)
  OWNER TO openpg;





-- Function: public.get_flujo_efectivo(boolean, integer, integer)

-- DROP FUNCTION public.get_flujo_efectivo(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_flujo_efectivo(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(periodo character varying, code character varying, concept character varying, debe numeric, haber numeric, saldo numeric, orden integer, grupo character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
    
select 
ap.name, ace.code,ace.concept,
CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END as debe, 
CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END as haber, 
CASE WHEN $1 THEN sum(aml.debit_me)- sum(aml.credit_me) ELSE sum(aml.debit)- sum(aml.credit) END as saldo, 
ace.order as orden, ace."group"
from account_move_line aml 
inner join account_move am on am.id = aml.move_id
inner join account_account aa on aa.id = aml.account_id
inner join account_config_efective ace on ace.id = aml.fefectivo_id
inner join account_period ap on ap.id = aml.period_id
where fefectivo_id is not null and aa.type = 'liquidity' and periodo_num(ap.name)>=$2 and periodo_num(ap.name)<=$3
and am.state != 'draft'
group by ap.name,ace.code , ace.concept, ace.order, ace."group"
order by ace.order;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_flujo_efectivo(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_hoja_trabajo_detalle(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, clasificationactual character varying, levelactual character varying, cuentaactual character varying, clasification character varying, level character varying, periodo character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.clasificationactual,
    t.levelactual,
    t.cuentaactual,
    t.clasification,
    t.level,
    t.periodo,
    t.cuenta,
    t.descripcion,
    t.debe,
    t.haber,
    t.saldodeudor,
    t.saldoacredor,
    t.activo,
    t.pasivo,
    t.perdidasnat,
    t.ganancianat,
    t.perdidasfun,
    t.gananciafun
   FROM ( SELECT *, 

                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe > M.haber THEN M.debe - M.haber
                    ELSE 0::numeric
                END AS activo,
                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe < M.haber THEN M.haber - M.debe
                    ELSE 0::numeric
                END AS pasivo,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasnat,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS ganancianat,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasfun,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS gananciafun


    FROM (

    SELECT aapadre.clasification_sheet AS clasificationactual,
            aa.level_sheet AS levelactual,
            aa.code AS cuentaactual,
            aa.clasification_sheet AS clasification,
            aapadre.level_sheet AS level,
            ap.name AS periodo,
            aapadre.code AS cuenta,
            aapadre.name AS descripcion,
            CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END AS debe,
            CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END AS haber,
            CASE WHEN $1 THEN (CASE
                    WHEN sum(aml.debit_me) > sum(aml.credit_me) THEN sum(aml.debit_me) - sum(aml.credit_me)
                    ELSE 0::numeric
                END)
            ELSE
                (CASE
                    WHEN sum(aml.debit) > sum(aml.credit) THEN sum(aml.debit) - sum(aml.credit)
                    ELSE 0::numeric
                END) END AS saldodeudor,
             CASE WHEN $1 THEN
             (CASE
                    WHEN sum(aml.debit_me) < sum(aml.credit_me) THEN sum(aml.credit_me) - sum(aml.debit_me)
                    ELSE 0::numeric
                END)
             ELSE
                (CASE
                    WHEN sum(aml.debit) < sum(aml.credit) THEN sum(aml.credit) - sum(aml.debit)
                    ELSE 0::numeric
                END) END AS saldoacredor
                
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             JOIN account_account aapadre ON aapadre.code::text = "substring"(''::text || aa.code::text, 0, 3)
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
          WHERE aapadre.level_sheet IS NOT NULL and aa.level_sheet IS NOT NULL and periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
          and am.state != 'draft'
          GROUP BY aa.code, aa.level_sheet, aa.clasification_sheet, ap.name, aapadre.code, aapadre.level_sheet, aapadre.clasification_sheet, aapadre.name
          ORDER BY ap.name, aapadre.code)as  M ) t;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_hoja_trabajo_detalle_balance(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_balance(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_balance(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY    
select row_number() OVER () AS id,T.* from (
select M.cuenta,M.descripcion, sum(M.debe),sum(M.haber),
CASE WHEN sum(M.saldodeudor) -sum(M.saldoacredor)> 0 THEN sum(M.saldodeudor) -sum(M.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(M.saldoacredor) -sum(M.saldodeudor)> 0 THEN sum(M.saldoacredor) -sum(M.saldodeudor) ELSE 0 END as saldoacredor,
CASE WHEN sum(M.activo)-sum(M.pasivo)>0 THEN sum(M.activo)-sum(M.pasivo) ELSE 0 END as activo,
CASE WHEN sum(M.pasivo)-sum(M.activo)>0 THEN sum(M.pasivo)-sum(M.activo) ELSE 0 END as pasivo,
CASE WHEN sum(M.perdidasnat)-sum(M.ganancianat) >0 THEN sum(M.perdidasnat)-sum(M.ganancianat) ELSE 0 END as perdidasnat,
CASE WHEN sum(M.ganancianat)-sum(M.perdidasnat) >0 THEN sum(M.ganancianat)-sum(M.perdidasnat) ELSE 0 END as ganancianat,
CASE WHEN sum(M.perdidasfun)-sum(M.gananciafun) >0 THEN sum(M.perdidasfun)-sum(M.gananciafun) ELSE 0 END as perdidasfun,
CASE WHEN sum(M.gananciafun)-sum(M.perdidasfun) >0 THEN sum(M.gananciafun)-sum(M.perdidasfun) ELSE 0 END as gananciafun
from get_hoja_trabajo_detalle($1,$2,$3) as M
group by M.cuenta,M.descripcion
order by M.cuenta
) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_balance(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_hoja_trabajo_detalle_registro(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_registro(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_registro(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY    
select row_number() OVER () AS id,T.* from (
select M.cuentaactual,aa.name as descripcion, sum(M.debe),sum(M.haber),
CASE WHEN sum(M.saldodeudor) -sum(M.saldoacredor)> 0 THEN sum(M.saldodeudor) -sum(M.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(M.saldoacredor) -sum(M.saldodeudor)> 0 THEN sum(M.saldoacredor) -sum(M.saldodeudor) ELSE 0 END as saldoacredor,
CASE WHEN sum(M.activo)-sum(M.pasivo)>0 THEN sum(M.activo)-sum(M.pasivo) ELSE 0 END as activo,
CASE WHEN sum(M.pasivo)-sum(M.activo)>0 THEN sum(M.pasivo)-sum(M.activo) ELSE 0 END as pasivo,
CASE WHEN sum(M.perdidasnat)-sum(M.ganancianat) >0 THEN sum(M.perdidasnat)-sum(M.ganancianat) ELSE 0 END as perdidasnat,
CASE WHEN sum(M.ganancianat)-sum(M.perdidasnat) >0 THEN sum(M.ganancianat)-sum(M.perdidasnat) ELSE 0 END as ganancianat,
CASE WHEN sum(M.perdidasfun)-sum(M.gananciafun) >0 THEN sum(M.perdidasfun)-sum(M.gananciafun) ELSE 0 END as perdidasfun,
CASE WHEN sum(M.gananciafun)-sum(M.perdidasfun) >0 THEN sum(M.gananciafun)-sum(M.perdidasfun) ELSE 0 END as gananciafun
from get_hoja_trabajo_detalle($1,$2,$3) as M
inner join account_account aa ON aa.code = cuentaactual
group by M.cuentaactual,aa.name) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_registro(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_hoja_trabajo_detalle_six(boolean, integer, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_six(boolean, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_six(
    IN boolean,
    IN integer,
    IN integer,
    IN integer)
  RETURNS TABLE(id bigint, level character varying, clasificationactual character varying, cuenta text, description character varying, levelactual character varying, clasification character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select row_number() OVER () AS id,* from (
select '0'::varchar as level,'0'::varchar as clasificationactual,CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END as cuenta,aa.name as description, '0'::varchar as levelactual, '0'::varchar as clasification, 
sum(T.debe) as debe,
sum(T.haber) as haber,

CASE WHEN sum(T.saldodeudor) - sum(T.saldoacredor)>0 THEN  sum(T.saldodeudor) - sum(T.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(T.saldoacredor) - sum(T.saldodeudor)>0 THEN  sum(T.saldoacredor) - sum(T.saldodeudor) ELSE 0 END as saldoacredor,

CASE WHEN sum(T.activo) - sum(T.pasivo)>0 THEN  sum(T.activo) - sum(T.pasivo) ELSE 0 END as activo,
CASE WHEN sum(T.pasivo) - sum(T.activo)>0 THEN  sum(T.pasivo) - sum(T.activo) ELSE 0 END as pasivo,

CASE WHEN sum(T.perdidasnat) - sum(T.ganancianat)>0 THEN  sum(T.perdidasnat) - sum(T.ganancianat) ELSE 0 END as perdidasnat,
CASE WHEN sum(T.ganancianat) - sum(T.perdidasnat)>0 THEN  sum(T.ganancianat) - sum(T.perdidasnat) ELSE 0 END as ganancianat,


CASE WHEN sum(T.perdidasfun) - sum(T.gananciafun)>0 THEN  sum(T.perdidasfun) - sum(T.gananciafun) ELSE 0 END as perdidasfun,
CASE WHEN sum(T.gananciafun) - sum(T.perdidasfun)>0 THEN  sum(T.gananciafun) - sum(T.perdidasfun) ELSE 0 END as gananciafun

from get_hoja_trabajo_detalle( $1,$2,$3) as T
left join account_account aa on aa.name = CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END 
group by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END, aa.name 
order by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END
) AS T;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_six(boolean, integer, integer, integer)
  OWNER TO openpg;



-- Function: public.get_hoja_trabajo_detalle_temporal(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_detalle_temporal(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_detalle_temporal(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, clasificationactual character varying, levelactual character varying, cuentaactual character varying, clasification character varying, level character varying, periodo character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.clasificationactual,
    t.levelactual,
    t.cuentaactual,
    t.clasification,
    t.level,
    t.periodo,
    t.cuenta,
    t.descripcion,
    t.debe,
    t.haber,
    t.saldodeudor,
    t.saldoacredor,
    t.activo,
    t.pasivo,
    t.perdidasnat,
    t.ganancianat,
    t.perdidasfun,
    t.gananciafun
   FROM ( SELECT *, 

                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe > M.haber THEN M.debe - M.haber
                    ELSE 0::numeric
                END AS activo,
                CASE
                    WHEN M.clasification::text = '1'::text AND M.debe < M.haber THEN M.haber - M.debe
                    ELSE 0::numeric
                END AS pasivo,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasnat,
                CASE
                    WHEN (M.clasification::text = '2'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS ganancianat,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) > (M.haber) THEN (M.debe) - (M.haber)
                    ELSE 0::numeric
                END AS perdidasfun,
                CASE
                    WHEN (M.clasification::text = '3'::text OR M.clasification::text = '6'::text) AND (M.debe) < (M.haber) THEN (M.haber) - (M.debe)
                    ELSE 0::numeric
                END AS gananciafun


    FROM (

    SELECT aapadre.clasification_sheet AS clasificationactual,
            aa.level_sheet AS levelactual,
            aa.code AS cuentaactual,
            aa.clasification_sheet AS clasification,
            aapadre.level_sheet AS level,
            ap.name AS periodo,
            aapadre.code AS cuenta,
            aapadre.name AS descripcion,
            CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END AS debe,
            CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END AS haber,
            CASE WHEN $1 THEN (CASE
                    WHEN sum(aml.debit_me) > sum(aml.credit_me) THEN sum(aml.debit_me) - sum(aml.credit_me)
                    ELSE 0::numeric
                END)
            ELSE
                (CASE
                    WHEN sum(aml.debit) > sum(aml.credit) THEN sum(aml.debit) - sum(aml.credit)
                    ELSE 0::numeric
                END) END AS saldodeudor,
             CASE WHEN $1 THEN
             (CASE
                    WHEN sum(aml.debit_me) < sum(aml.credit_me) THEN sum(aml.credit_me) - sum(aml.debit_me)
                    ELSE 0::numeric
                END)
             ELSE
                (CASE
                    WHEN sum(aml.debit) < sum(aml.credit) THEN sum(aml.credit) - sum(aml.debit)
                    ELSE 0::numeric
                END) END AS saldoacredor
                
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             LEFT JOIN account_account aapadre ON aapadre.code::text = "substring"(''::text || aa.code::text, 0, 3)
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
          WHERE aapadre.level_sheet IS NULL and aa.level_sheet IS NULL and periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
          and am.state != 'draft'
          GROUP BY aa.code, aa.level_sheet, aa.clasification_sheet, ap.name, aapadre.code, aapadre.level_sheet, aapadre.clasification_sheet, aapadre.name
          ORDER BY ap.name, aapadre.code)as  M ) t;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_detalle_temporal(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_hoja_trabajo_simple(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, clasificationactual character varying, levelactual character varying, clasification character varying, level character varying, periodo character varying, cuenta character varying, cuentaactual character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.clasificationactual,
    t.levelactual,
    t.clasification,
    t.level,
    t.periodo,
    t.cuenta,
    t.cuentaactual,
    t.descripcion,
    t.debe,
    t.haber,
    t.saldodeudor,
    t.saldoacredor
   FROM ( SELECT aa.clasification_sheet AS clasificationactual,
            aa.level_sheet AS levelactual,
            aapadre.clasification_sheet AS clasification,
            aapadre.level_sheet AS level,
            ap.name AS periodo,
            aapadre.code AS cuenta,
            aa.code AS cuentaactual,
            aapadre.name AS descripcion,
            CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END AS debe,
            CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END AS haber,
            CASE WHEN $1 THEN (CASE
                    WHEN sum(aml.debit_me) > sum(aml.credit_me) THEN sum(aml.debit_me) - sum(aml.credit_me)
                    ELSE 0::numeric
                END)
            ELSE
                (CASE
                    WHEN sum(aml.debit) > sum(aml.credit) THEN sum(aml.debit) - sum(aml.credit)
                    ELSE 0::numeric
                END) END AS saldodeudor,
             CASE WHEN $1 THEN
             (CASE
                    WHEN sum(aml.debit_me) < sum(aml.credit_me) THEN sum(aml.credit_me) - sum(aml.debit_me)
                    ELSE 0::numeric
                END)
             ELSE
                (CASE
                    WHEN sum(aml.debit) < sum(aml.credit) THEN sum(aml.credit) - sum(aml.debit)
                    ELSE 0::numeric
                END) END AS saldoacredor
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             JOIN account_account aapadre ON aapadre.code::text = "substring"(''::text || aa.code::text, 0, 3)
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
             where periodo_num(ap.name) >=$2 and  periodo_num(ap.name) <=$3
             and am.state != 'draft'
          GROUP BY aa.code, aa.level_sheet, aa.clasification_sheet, ap.name, aapadre.code, aapadre.level_sheet, aapadre.clasification_sheet, aapadre.name
          ORDER BY ap.name, aapadre.code) t;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_hoja_trabajo_simple_balance(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple_balance(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple_balance(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
   select row_number() OVER () AS id,* from (
select M.cuenta,M.descripcion, sum(M.debe) as debe,sum(M.haber) as haber ,
CASE WHEN sum(M.saldodeudor) - sum(M.saldoacredor) >0 THEN sum(M.saldodeudor) - sum(M.saldoacredor) ELSE 0 END  as saldodeudor,
CASE WHEN sum(M.saldodeudor) - sum(M.saldoacredor) <0 THEN sum(M.saldoacredor) - sum(M.saldodeudor) ELSE 0 END  as saldoacredor
from get_hoja_trabajo_simple($1,$2,$3) as M
group by M.cuenta,M.descripcion
order by M.cuenta) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple_balance(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_hoja_trabajo_simple_registro(boolean, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple_registro(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple_registro(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
   select row_number() OVER () AS id,* from (
select hoja.cuentaactual as cuenta,aa.name as descripcion, sum(hoja.debe) as debe,sum(hoja.haber) as haber ,
CASE WHEN sum(hoja.saldodeudor) - sum(hoja.saldoacredor) >0 THEN sum(hoja.saldodeudor) - sum(hoja.saldoacredor) ELSE 0 END  as saldodeudor,
CASE WHEN sum(hoja.saldodeudor) - sum(hoja.saldoacredor) <0 THEN sum(hoja.saldoacredor) - sum(hoja.saldodeudor) ELSE 0 END  as saldoacredor
from get_hoja_trabajo_simple($1,$2,$3) as hoja
inner join account_account aa on aa.code= hoja.cuentaactual 
group by hoja.cuentaactual,aa.name
order by hoja.cuentaactual) AS T;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple_registro(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_hoja_trabajo_simple_six(boolean, integer, integer, integer)

-- DROP FUNCTION public.get_hoja_trabajo_simple_six(boolean, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.get_hoja_trabajo_simple_six(
    IN boolean,
    IN integer,
    IN integer,
    IN integer)
  RETURNS TABLE(id bigint, level character varying, clasificationactual character varying, cuenta text, description character varying, levelactual character varying, clasification character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select row_number() OVER () AS id,* from (
select '0'::varchar as level,'0'::varchar as clasificationactual,CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END as cuenta,aa.name as description, '0'::varchar as levelactual, '0'::varchar as clasification, 
sum(T.debe) as debe,
sum(T.haber) as haber,

CASE WHEN sum(T.saldodeudor) - sum(T.saldoacredor)>0 THEN  sum(T.saldodeudor) - sum(T.saldoacredor) ELSE 0 END as saldodeudor,
CASE WHEN sum(T.saldoacredor) - sum(T.saldodeudor)>0 THEN  sum(T.saldoacredor) - sum(T.saldodeudor) ELSE 0 END as saldoacredor

from get_hoja_trabajo_simple( $1,$2,$3) as T
left join account_account aa on aa.name = CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END 
group by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END, aa.name 
order by CASE WHEN $4 = 8 THEN T.cuentaactual ELSE substring( T.cuentaactual, 0, $4) END
) AS T;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_hoja_trabajo_simple_six(boolean, integer, integer, integer)
  OWNER TO openpg;




-- Function: public.get_honorarios_1(boolean, integer, integer)

-- DROP FUNCTION public.get_honorarios_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_honorarios_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(comprobante character varying, am_id integer, clasifica character varying, base_impuesto numeric, monto numeric, record_fees character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT account_move.dec_reg_nro_comprobante AS comprobante,
    account_move.id AS am_id,
    account_tax_code.name AS clasifica,
    CASE WHEN $1 THEN  
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END )
      
      ELSE account_move_line.tax_amount END AS base_impuesto,
    CASE WHEN $1 THEN  
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END )
      ELSE account_move_line.tax_amount END AS monto,
    account_tax_code.record_fees
   FROM account_move
     JOIN account_move_line ON account_move.id = account_move_line.move_id
     JOIN account_journal ON account_move_line.journal_id = account_journal.id AND account_move.journal_id = account_journal.id
     JOIN account_period ON account_move.period_id = account_period.id AND account_move.period_id = account_period.id
     
     LEFT JOIN it_type_document ON account_move_line.type_document_id = it_type_document.id AND account_move.dec_mod_type_document_id = it_type_document.id AND account_move.dec_reg_type_document_id = it_type_document.id
     LEFT JOIN res_partner ON account_move.partner_id = res_partner.id AND account_move_line.partner_id = res_partner.id
     LEFT JOIN it_type_document_partner ON res_partner.type_document_id = it_type_document_partner.id
     JOIN account_tax_code ON account_move_line.tax_code_id = account_tax_code.id
  WHERE account_tax_code.record_fees IS NOT NULL and periodo_num(account_period.name) >= $2 and periodo_num(account_period.name) <= $3
  and account_move.state != 'draft'
  ORDER BY account_move.dec_reg_nro_comprobante;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_honorarios_1(boolean, integer, integer)
  OWNER TO openpg;







-- Function: public.get_honorarios_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_honorarios_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_honorarios_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(am_id integer, "1" numeric, "2" numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
 SELECT crosstab.am_id,
    crosstab."1",
    crosstab."2"
   FROM crosstab('SELECT h1.am_id ,h1.record_fees,
  sum(h1.monto) as monto FROM get_honorarios_1(' || $1 || ',' || $2 || ','|| $3 || ') as h1
  GROUP BY h1.am_id, h1.record_fees
  ORDER BY 1,2,3'::text, '  select m from generate_series(1,2) m'::text) crosstab(am_id integer, "1" numeric, "2" numeric);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_honorarios_1_1(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_honorarios_1_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_honorarios_1_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_honorarios_1_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, fechaemision date, fechapago date, tipodocumento character varying, serie text, numero text, tipodoc character varying, numdoc character varying, partner character varying, divisa character varying, tipodecambio numeric, monto numeric, retencion numeric, neto numeric, state character varying, periodopago character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
  SELECT row_number() OVER () AS id,*
   FROM ( SELECT DISTINCT ap.name AS periodo,
            aj.code AS libro,
            am.name AS voucher,
            am.date AS fechaemision,
                CASE
                    WHEN ai.state::text = 'paid'::text THEN pago.date::date
                    ELSE ai.date_due::date
                END AS fechapago,
            itd.code AS tipodocumento,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN NULL::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, 0, "position"(am.dec_reg_nro_comprobante::text, '-'::text))
                END AS serie,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN am.dec_reg_nro_comprobante::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, "position"(am.dec_reg_nro_comprobante::text, '-'::text) + 1)
                END AS numero,
            itdp.code AS tipodoc,
            rp.type_number AS numdoc,
            rp.name AS partner,
            rc.name AS divisa,

            CASE WHEN $1 THEN am.com_det_type_change
            ELSE
            CASE WHEN rc.name = 'USD' THEN am.com_det_type_change ELSE Null::numeric END END AS tipodecambio,
            pr.monto,
            pr.retencion,
            pr.total AS neto,
            ai.state,
                CASE
                    WHEN ai.state::text = 'paid'::text THEN ap_pago.name
                    ELSE NULL::character varying
                END AS periodopago
           FROM ( SELECT vst_reg_forth_1_1.am_id,
                    sum(vst_reg_forth_1_1."1") AS monto,
                    sum(vst_reg_forth_1_1."2") AS retencion,
                    COALESCE(sum(vst_reg_forth_1_1."1"), 0::numeric) - abs(COALESCE(sum(vst_reg_forth_1_1."2"), 0::numeric)) AS total
                   FROM get_honorarios_1_1($1,$2,$3) as vst_reg_forth_1_1
                  GROUP BY vst_reg_forth_1_1.am_id) pr
             JOIN account_move am ON am.id = pr.am_id
             JOIN account_journal aj ON aj.id = am.journal_id
             JOIN account_period ap ON ap.id = am.period_id
             LEFT JOIN it_type_document itd ON itd.id = am.dec_reg_type_document_id
             LEFT JOIN res_partner rp ON rp.id = am.partner_id
             LEFT JOIN it_type_document_partner itdp ON itdp.id = rp.type_document_id
             LEFT JOIN res_currency rc ON rc.id = am.com_det_currency
             LEFT JOIN account_invoice ai ON ai.move_id = am.id
              LEFT JOIN account_perception adr ON adr.father_invoice_id = ai.id
             LEFT JOIN it_type_document itd2 ON itd2.id = am.dec_mod_type_document_id
             LEFT JOIN account_move_line pago ON pago.id = (( SELECT max(pagoc.id) AS max
                   FROM account_move amc
                     JOIN account_move_line amlc ON amlc.move_id = amc.id
                     JOIN account_move_line pagoc ON amlc.reconcile_id = pagoc.reconcile_id
                  WHERE amc.id = am.id AND amlc.id <> pagoc.id
                  GROUP BY am.id))
             LEFT JOIN account_period ap_pago ON ap_pago.id = pago.period_id
             CROSS JOIN main_parameter mp
             where am.state != 'draft'
          ORDER BY ap.name, aj.code, am.name) t;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_honorarios_1_1_1(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_kardex(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex(
    IN date_ini integer,
    IN date_end integer,
    IN integer[],
    IN integer[])
  RETURNS TABLE(almacen character varying, categoria character varying, name_template character varying, fecha date, periodo character varying, ctanalitica character varying, serial character varying, nro character varying, operation_type character varying, name character varying, ingreso numeric, salida numeric, saldof numeric, debit numeric, credit numeric, cadquiere numeric, saldov numeric, cprom numeric, type character varying, esingreso text, product_id integer, location_id integer, doc_type_ope character varying) AS
$BODY$  
BEGIN
return query select * from vst_kardex_sunat where fecha_num(vst_kardex_sunat.fecha) between $1 and $2 and vst_kardex_sunat.product_id = ANY($3) and vst_kardex_sunat.location_id = ANY($4);
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_kardex(integer, integer, integer[], integer[])
  OWNER TO openpg;





-- Function: public.get_kardex_fis(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex_fis(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex_fis(
    IN date_ini integer,
    IN date_end integer,
    IN integer[],
    IN integer[])
  RETURNS TABLE(almacen character varying, categoria character varying, name_template character varying, fecha date, periodo character varying, ctanalitica character varying, serial character varying, nro character varying, operation_type character varying, name character varying, ingreso numeric, salida numeric, saldof numeric, debit numeric, credit numeric, cadquiere numeric, saldov numeric, cprom numeric, type character varying, esingreso text, product_id integer, location_id integer, doc_type_ope character varying) AS
$BODY$  
BEGIN
return query select * from vst_kardex_fis_sunat where fecha_num(vst_kardex_fis_sunat.fecha) between $1 and $2 and vst_kardex_fis_sunat.product_id = ANY($3) and vst_kardex_fis_sunat.location_id = ANY($4);
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_kardex_fis(integer, integer, integer[], integer[])
  OWNER TO openpg;



-- Function: public.get_kardex_fis_sumi(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex_fis_sumi(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex_fis_sumi(
    IN date_ini integer,
    IN date_end integer,
    IN integer[],
    IN integer[])
  RETURNS TABLE(almacen character varying, categoria character varying, name_template character varying, fecha date, periodo character varying, ctanalitica character varying, serial character varying, nro character varying, operation_type character varying, name character varying, ingreso numeric, salida numeric, saldof numeric, debit numeric, credit numeric, cadquiere numeric, saldov numeric, cprom numeric, type character varying, esingreso text, product_id integer, location_id integer, doc_type_ope character varying) AS
$BODY$  
BEGIN
return query select * from vst_kardex_fissumi_sunat where fecha_num(vst_kardex_fis_sunat.fecha) between $1 and $2 and vst_kardex_fis_sunat.product_id = ANY($3) and vst_kardex_fis_sunat.location_id = ANY($4);
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_kardex_fis_sumi(integer, integer, integer[], integer[])
  OWNER TO openpg;




-- Function: public.get_kardex_v(integer, integer, integer[], integer[])

-- DROP FUNCTION public.get_kardex_v(integer, integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.get_kardex_v(
    IN date_ini integer,
    IN date_end integer,
    IN productos integer[],
    IN almacenes integer[],
    OUT almacen character varying,
    OUT categoria character varying,
    OUT name_template character varying,
    OUT fecha date,
    OUT periodo character varying,
    OUT ctanalitica character varying,
    OUT serial character varying,
    OUT nro character varying,
    OUT operation_type character varying,
    OUT name character varying,
    OUT ingreso numeric,
    OUT salida numeric,
    OUT saldof numeric,
    OUT debit numeric,
    OUT credit numeric,
    OUT cadquiere numeric,
    OUT saldov numeric,
    OUT cprom numeric,
    OUT type character varying,
    OUT esingreso text,
    OUT product_id integer,
    OUT location_id integer,
    OUT doc_type_ope character varying,
    OUT ubicacion_origen integer,
    OUT ubicacion_destino integer,
    OUT stock_moveid integer,
    OUT account_invoice character varying,
    OUT product_account character varying,
    OUT default_code character varying,
    OUT unidad character varying,
    OUT mrpname character varying,
    OUT ruc character varying,
    OUT comapnyname character varying,
    OUT cod_sunat character varying,
    OUT tipoprod character varying,
    OUT coduni character varying,
    OUT metodo character varying,
    OUT cu_entrada numeric,
    OUT cu_salida numeric,
    OUT period_name character varying,
    OUT stock_doc character varying,
    OUT origen character varying,
    OUT destino character varying,
    OUT type_doc character varying,
    OUT numdoc_cuadre character varying,
    OUT doc_partner character varying,
    OUT fecha_albaran date,
    OUT pedido_compra character varying,
    OUT licitacion character varying,
    OUT doc_almac character varying,
    OUT lote character varying)
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

  select res_partner.name,res_partner.type_number from res_company 
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


        

           ruc = h.type_number;
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
          if dr.serial is not null then 
            debit=coalesce(dr.debit,0);
          else
            if dr.ubicacion_origen=8 then
              debit =0;
            else
              debit = coalesce(dr.debit,0);
            end if;
          end if;
          

          
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
ALTER FUNCTION public.get_kardex_v(integer, integer, integer[], integer[])
  OWNER TO openpg;




-- Function: public.get_libro_diario(boolean, integer, integer)

-- DROP FUNCTION public.get_libro_diario(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_libro_diario(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, divisa character varying, tipodecambio numeric, importedivisa numeric, codigo character varying, partner character varying, tipodocumento character varying, numero character varying, fechaemision date, fechavencimiento date, glosa character varying, ctaanalitica character varying, refconcil character varying, statefiltro character varying, aml_id integer, aj_id integer, ap_id integer, am_id integer, aa_id integer, rc_id integer, rp_id integer, itd_id integer, aaa_id integer, state character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,*
   FROM ( SELECT ap.name AS periodo,
            aj.code AS libro,
            am.name AS voucher,
            aa.code AS cuenta,
            aa.name AS descripcion,
            CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
            CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
            rc.name AS divisa,
            CASE WHEN $1 THEN aml.currency_rate_it
            ELSE
            CASE WHEN rc.name ='USD' THEN aml.currency_rate_it ELSE Null::numeric END END AS tipodecambio,
            aml.amount_currency AS importedivisa,
            rp.type_number AS codigo,
            rp.name AS partner,
            itd.code AS tipodocumento,
            aml.nro_comprobante AS numero,
            aml.date AS fechaemision,
            aml.date_maturity AS fechavencimiento,
            aml.name AS glosa,
            aaa.name AS ctaanalitica,
            aml.reconcile_ref AS refconcil,
            am.state AS statefiltro,
            aml.id AS aml_id,
            aj.id AS aj_id,
            ap.id AS ap_id,
            am.id AS am_id,
            aa.id AS aa_id,
            rc.id AS rc_id,
            rp.id AS rp_id,
            itd.id AS itd_id,
            aaa.id AS aaa_id,
            case when am.state = 'posted'::varchar then 'Asentado'::varchar ELSE 'Borrador'::varchar END as state
           FROM account_move_line aml
             JOIN account_journal aj ON aj.id = aml.journal_id
             JOIN account_period ap ON ap.id = aml.period_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_account aa ON aa.id = aml.account_id
             LEFT JOIN res_currency rc ON rc.id = aml.currency_id
             LEFT JOIN res_partner rp ON rp.id = aml.partner_id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
             LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
             where am.state != 'draft'
          ORDER BY ap.id, aj.code, am.name) t
          where periodo_num(t.periodo) >= $2 and periodo_num(t.periodo)<=$3;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_libro_diario(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_libro_mayor(boolean, integer, integer)

-- DROP FUNCTION public.get_libro_mayor(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_libro_mayor(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, periodo character varying, libro character varying, voucher character varying, cuenta character varying, descripcion character varying, debe numeric, haber numeric, divisa character varying, tipocambio numeric, importedivisa numeric, conciliacion character varying, fechaemision date, fechavencimiento date, tipodocumento character varying, numero character varying, ruc character varying, partner character varying, glosa character varying, analitica character varying, ordenamiento integer, cuentaname character varying, aml_id integer, state character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,* from ( (SELECT ap.name AS periodo,
                    aj.code AS libro,
                    am.name AS voucher,
                    aa.code AS cuenta,
                    aa.name AS descripcion,
                    CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
      CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
                    rc.name AS divisa,

            CASE WHEN $1 THEN aml.currency_rate_it
            ELSE
                    CASE WHEN rc.name = 'USD' THEN aml.currency_rate_it ELSE Null::numeric END END AS tipocambio,
                    aml.amount_currency AS importedivisa,
                    aml.reconcile_ref AS conciliacion,
                    aml.date AS fechaemision,
                    aml.date_maturity AS fechavencimiento,
                    itd.code AS tipodocumento,
                    aml.nro_comprobante AS numero,
                    rp.type_number AS ruc,
                    rp.name AS partner,
                    aml.name AS glosa,
                    aaa.code AS analitica,
                    1 AS ordenamiento,
                        CASE
                            WHEN "position"(aa.name::varchar, '-'::varchar) = 0 THEN aa.name::varchar
                            ELSE "substring"(aa.name::varchar, 0, "position"(aa.name::varchar, '-'::varchar))::varchar
                        END AS cuentaname,
                    aml.id as aml_id,
                    case when am.state = 'draft' then 'Borrador'::varchar else 'Asentado'::varchar END as state
                   FROM account_move_line aml
                     JOIN account_journal aj ON aml.journal_id = aj.id
                     JOIN account_move am ON aml.move_id = am.id
                     JOIN account_account aa ON aml.account_id = aa.id
                     JOIN account_period ap ON ap.id = aml.period_id
                     LEFT JOIN res_currency rc ON aml.currency_id = rc.id
             LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
                     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
                     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
                   WHERE periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
                   and am.state != 'draft')
  
                  UNION ALL
                  (
    SELECT  
      periodo_string($2) as periodo,  
      Null::varchar as libro,
      Null::varchar as voucher, 
      aa.code as Cuenta, 
      aa.name as descripcion,
       CASE WHEN $1 THEN (CASE WHEN sum(aml.debit_me) - sum(aml.credit_me) >0 THEN sum(aml.debit_me) - sum(aml.credit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN sum(aml.debit) - sum(aml.credit) ELSE 0 END) END AS debe,
      CASE WHEN $1 THEN (CASE WHEN sum(aml.credit_me) - sum(aml.debit_me) >0 THEN sum(aml.credit_me) - sum(aml.debit_me) ELSE 0 END) ELSE (CASE WHEN sum(aml.credit) - sum(aml.debit) >0 THEN sum(aml.credit) - sum(aml.debit) ELSE 0 END) END AS haber,
    
       Null::varchar as divisa,
       Null::numeric as tipocambio,
       Null::numeric as importedivisa,
       Null::varchar as conciliacion,
       Null::date as fechaemision,
       Null::date as fechavencimiento,
       Null::varchar as tipodocumento,
       Null::varchar as numero,
       Null::varchar as ruc,
       Null::varchar as partner,
       'Saldo Inicial'::varchar as glosa,
       Null::varchar as analitica,
       0 as ordenamiento,
       Null::varchar as cuentaname,
       Null::integer as aml_id,
       'Asentado'::varchar as state
    FROM
      account_move_line aml
      INNER JOIN account_journal aj ON (aml.journal_id = aj.id)
      INNER JOIN account_move am ON (aml.move_id = am.id)
      INNER JOIN account_account aa ON (aml.account_id = aa.id)
      INNER JOIN account_period ap_1 ON (ap_1.id = aml.period_id)
      LEFT OUTER JOIN res_currency rc ON (aml.currency_id = rc.id)
      LEFT OUTER JOIN res_partner rp ON (rp.id = aml.partner_id)
      LEFT OUTER JOIN account_analytic_account aaa ON (aaa.id = aml.analytic_account_id)
    WHERE periodo_num(ap_1.name) < $2 
    and am.state != 'draft'
    group by aa.code, aa.name) 
    order by cuenta,ordenamiento,periodo,fechaemision) AS T; 

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_libro_mayor(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_max_min(integer, character varying, character varying, character varying, integer[])

-- DROP FUNCTION public.get_max_min(integer, character varying, character varying, character varying, integer[]);

CREATE OR REPLACE FUNCTION public.get_max_min(
    IN rotacion integer,
    IN evaluacion character varying,
    IN fr_str character varying,
    IN td_str character varying,
    IN wh_id integer[])
  RETURNS TABLE(product_id integer, uom_id integer, category character varying, rotation numeric, saldo numeric, minimo numeric, maximo numeric, reponer numeric, sobrante numeric, abastecimiento numeric) AS
$BODY$

BEGIN
RETURN QUERY

select
    pp.id as product_id,
    pt.uom_id as uom_id,
     pc.name as category,

    (case when swo.estimated_rotation > 0 then swo.estimated_rotation else coalesce((select * from get_rotation(pp.id, $3, $4)),0) end) as rotation,

     coalesce((select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss ),0) as saldo,
     (case when swo.max_min > 0 then coalesce(swo.product_min_qty,0)/swo.max_min*$1 else coalesce(swo.product_min_qty,0) end) as minimo,
     (case when swo.max_min > 0 then coalesce(swo.product_max_qty,0)/swo.max_min*$1 else coalesce(swo.product_max_qty,0) end) as maximo,

     (case
        when ($2 = 'faltantes')
        then (case when swo.max_min > 0 then coalesce(swo.product_max_qty,0)/swo.max_min*$1 else coalesce(swo.product_max_qty,0) end) - (select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss where rss.product_id = pp.id)
        else 0 end) as reponer,

    (case
        when ($2 = 'sobrantes')
        then (select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss where rss.product_id = pp.id) - (case when swo.max_min > 0 then coalesce(swo.product_max_qty,0)/swo.max_min*$1 else coalesce(swo.product_max_qty,0) end)
        else 0 end) as sobrante,

    (case
        when coalesce((select * from get_rotation(pp.id, $3, $4)),0) != 0 and $1 != 0
        then round((select rss.saldores from rep_stock_saldo(fecha_num($4::date),array[pp.id],$5) rss where rss.product_id = pp.id)/( (case when swo.estimated_rotation > 0 then swo.estimated_rotation else coalesce((select * from get_rotation(pp.id, $3, $4)),0) end) / $1))
        else 0 end) as abastecimiento
     
from product_product pp
left join product_template pt on pp.product_tmpl_id = pt.id
left join product_category pc on pt.categ_id = pc.id
left join product_uom pu on pt.uom_id = pu.id
left join stock_warehouse_orderpoint swo on swo.product_id = pp.id
where pt.type != 'consu';

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_max_min(integer, character varying, character varying, character varying, integer[])
  OWNER TO openpg;




-- Function: public.get_moves_cost(integer, integer, integer[], integer[], character varying, character varying)

-- DROP FUNCTION public.get_moves_cost(integer, integer, integer[], integer[], character varying, character varying);

CREATE OR REPLACE FUNCTION public.get_moves_cost(
    IN integer,
    IN integer,
    IN integer[],
    IN integer[],
    IN character varying,
    IN character varying)
  RETURNS TABLE(out_account character varying, valued_account character varying, analytic_account character varying, producto integer, saldov numeric, category character varying) AS
$BODY$
BEGIN
    RETURN QUERY
    select 
    ip1.value_reference as out_account,
    ip2.value_reference as valued_account,
    result.ctanalitica as analytic_account,
    result.product_id as producto, 
    result.saldov as saldov,
    pc.name as category
    from (
    (select * from get_kardex_v($1,$2,$3,$4)) as result
    join stock_location sl on sl.id = result.ubicacion_origen and sl.usage = $5
    join stock_location sl2 on sl2.id = result.ubicacion_destino and sl2.usage = $6
    left join product_product pp on pp.id = result.product_id
    left join product_template pt on pt.id = pp.product_tmpl_id
    left join product_category pc on pt.categ_id = pc.id 
    left join ir_property ip1 on (ip1.res_id = 'product.category,' || pc.id) and ip1.name = 'property_stock_account_output_categ' 
    left join ir_property ip2 on (ip2.res_id = 'product.category,' || pc.id) and ip2.name = 'property_stock_valuation_account_id' )
    order by producto, saldov;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_moves_cost(integer, integer, integer[], integer[], character varying, character varying)
  OWNER TO openpg;




-- Function: public.get_periodo_libro(character varying)

-- DROP FUNCTION public.get_periodo_libro(character varying);

CREATE OR REPLACE FUNCTION public.get_periodo_libro(IN libro character varying)
  RETURNS TABLE(name character varying, periodo_num integer) AS
$BODY$
    Select distinct name,periodo_num(name) from account_period order by periodo_num(name)
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_periodo_libro(character varying)
  OWNER TO openpg;





-- Function: public.get_report_bank_with_saldoinicial(boolean, integer, integer)

-- DROP FUNCTION public.get_report_bank_with_saldoinicial(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_report_bank_with_saldoinicial(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, fecha date, cheque character varying, nombre character varying, documento character varying, glosa character varying, cargo_mn numeric, abono_mn numeric, tipo_cambio numeric, cargo_me numeric, abono_me numeric, nro_asiento integer, aa_id integer, ordenamiento integer, diario_id integer) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,*
   FROM ( SELECT * from(
    SELECT 
    aml.date AS fecha,
    aml.nro_comprobante AS cheque,
    rp.name as nombre,

    am.name as documento,
    
    aml.name as glosa,
    aml.debit as cargo_mn,
    aml.credit as abono_mn,
    aml.currency_rate_it as tipo_cambio,
    CASE WHEN aml.amount_currency>0 THEN aml.amount_currency ELSE 0 END as cargo_me,
    CASE WHEN aml.amount_currency<0 THEN -1*aml.amount_currency ELSE 0 END as abono_me,
    am.id as nro_asiento,
    aa.id as aa_id,
    1 as ordenamiento,
    aj.id as diario_id


    FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
     JOIN account_account aa ON aa.id = aml.account_id
     LEFT JOIN it_means_payment mp ON mp.id = aml.means_payment_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
     LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE periodo_num(ap.name) >= $2 and periodo_num(ap.name) <= $3
  and am.state != 'draft'
  
UNION ALL

SELECT 
    Null::date AS fecha,
    Null::varchar AS cheque,
    Null::varchar AS nombre,
    Null::varchar as documento,
    'Saldo Inicial' as glosa,
    sum(aml.debit) as cargo_mn,   
    sum(aml.credit) as abono_mn,
    Null::numeric as tipo_cambio,
    
    sum( CASE WHEN aml.amount_currency>0 THEN aml.amount_currency else 0 END ) as cargo_me,
    sum( CASE WHEN aml.amount_currency<0 THEN -1* aml.amount_currency ELSE 0 END) as abono_me,
    Null::integer as nro_asiento,
    aa.id as aa_id,
    0 as ordenamiento,
    0 as diario_id

    FROM account_move_line aml
     JOIN account_journal aj ON aj.id = aml.journal_id
     JOIN account_period ap ON ap.id = aml.period_id
     JOIN account_move am ON am.id = aml.move_id
     JOIN account_account aa ON aa.id = aml.account_id
     LEFT JOIN it_means_payment mp ON mp.id = aml.means_payment_id
     LEFT JOIN res_currency rc ON rc.id = aml.currency_id
     LEFT JOIN res_partner rp ON rp.id = aml.partner_id
     LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
     LEFT JOIN account_analytic_account aaa ON aaa.id = aml.analytic_account_id
  WHERE periodo_num(ap.name) >= (substring($2::varchar,0,5)||'0')::integer  and periodo_num(ap.name) < $2
  and am.state != 'draft'
  group by aa.id


  ) AS T
  order by ordenamiento,fecha,cheque,documento
  
  ) AS M;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_report_bank_with_saldoinicial(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_reporte_hoja_balance(boolean, integer, integer)

-- DROP FUNCTION public.get_reporte_hoja_balance(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_reporte_hoja_balance(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric, cuentaf character varying, totaldebe numeric, totalhaber numeric, finaldeudor numeric, finalacreedor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select X.id,X.cuenta,X.descripcion,X.debe,X.haber,X.saldodeudor,X.saldoacredor,
CASE WHEN ((X.activo >0 or X.pasivo >0) or (X.ver_pas=1) ) and X.finaldeudor>0 THEN X.finaldeudor ELSE 0 end activo,
CASE WHEN ((X.pasivo >0 or X.activo >0) or (X.ver_pas=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end pasivo,
CASE WHEN ((X.perdidasnat >0 or X.ganancianat >0) or (X.ver_nat=1) ) and X.finaldeudor>0 THEN X.finaldeudor  ELSE 0 end perdidasnat,
CASE WHEN ((X.ganancianat >0 or X.perdidasnat >0) or (X.ver_nat=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end ganancianat,
CASE WHEN ((X.perdidasfun >0 or X.gananciafun >0) or (X.ver_fun=1) ) and X.finaldeudor >0 THEN X.finaldeudor ELSE 0 end perdidasfun,
CASE WHEN ((X.gananciafun >0 or X.perdidasfun >0) or (X.ver_fun=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end gananciafun,
X.cuentaf,X.totaldebe,X.totalhaber,X.finaldeudor,X.finalacreedor

 from (select row_number() OVER () AS id,RES.* from 
  (select  CASE WHEN M.cuenta IS NOT NULL THEN M.cuenta ELSE aa_f.code END as cuenta, CASE WHEN M.descripcion IS NOT NULL THEN M.descripcion ELSE aa_f.name END as descripcion, M.debe, M.haber, M.saldodeudor, M.saldoacredor, M.activo, M.pasivo, M.perdidasnat, M.ganancianat, M.perdidasfun, M.gananciafun,T.cuentaF, T.totaldebe,T.totalhaber ,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) >0 THEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) ELSE 0 END as finaldeudor,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) <0 THEN -1 * (coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0)) ELSE 0 END as finalacreedor,
T.ver_pas, T.ver_nat, T.ver_fun
from get_hoja_trabajo_detalle_balance($1,(substring($2::varchar,0,5)||'01')::integer,$3) AS M 
FULL JOIN (select O1.cuenta as cuentaF,
--sum(O1.saldodeudor) as totaldebe,
--sum(O1.saldoacredor) as totalhaber   from get_hoja_trabajo_detalle_balance($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
sum(O1.debe) as totaldebe,
sum(O1.haber) as totalhaber,
CASE WHEN sum(O1.activo)> 0 or sum(O1.pasivo) >0 THEN 1 ELSE 0 END as ver_pas,
CASE WHEN sum(O1.perdidasnat)> 0 or sum(O1.ganancianat) >0 THEN 1 ELSE 0 END as ver_nat,
CASE WHEN sum(O1.perdidasfun)> 0 or sum(O1.gananciafun) >0 THEN 1 ELSE 0 END as ver_fun
   from get_hoja_trabajo_detalle_balance($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
group by O1.cuenta) AS T on T.cuentaF = M.cuenta
left join account_account aa_f on aa_f.code = T.cuentaF order by cuenta) RES ) AS X;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_reporte_hoja_balance(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_reporte_hoja_registro(boolean, integer, integer)

-- DROP FUNCTION public.get_reporte_hoja_registro(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_reporte_hoja_registro(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, cuenta character varying, descripcion character varying, debe numeric, haber numeric, saldodeudor numeric, saldoacredor numeric, activo numeric, pasivo numeric, perdidasnat numeric, ganancianat numeric, perdidasfun numeric, gananciafun numeric, cuentaf character varying, totaldebe numeric, totalhaber numeric, finaldeudor numeric, finalacreedor numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
select X.id,X.cuenta,X.descripcion,X.debe,X.haber,X.saldodeudor,X.saldoacredor,
CASE WHEN ((X.activo >0 or X.pasivo >0) or (X.ver_pas=1) ) and X.finaldeudor>0 THEN X.finaldeudor ELSE 0 end activo,
CASE WHEN ((X.pasivo >0 or X.activo >0) or (X.ver_pas=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end pasivo,
CASE WHEN ((X.perdidasnat >0 or X.ganancianat >0) or (X.ver_nat=1) ) and X.finaldeudor>0 THEN X.finaldeudor  ELSE 0 end perdidasnat,
CASE WHEN ((X.ganancianat >0 or X.perdidasnat >0) or (X.ver_nat=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end ganancianat,
CASE WHEN ((X.perdidasfun >0 or X.gananciafun >0) or (X.ver_fun=1) ) and X.finaldeudor >0 THEN X.finaldeudor ELSE 0 end perdidasfun,
CASE WHEN ((X.gananciafun >0 or X.perdidasfun >0) or (X.ver_fun=1) ) and X.finalacreedor>0 THEN X.finalacreedor ELSE 0 end gananciafun,
X.cuentaf,X.totaldebe,X.totalhaber,X.finaldeudor,X.finalacreedor

 from (select row_number() OVER () AS id,RES.* from 
  (select  CASE WHEN M.cuenta IS NOT NULL THEN M.cuenta ELSE aa_f.code END as cuenta, CASE WHEN M.descripcion IS NOT NULL THEN M.descripcion ELSE aa_f.name END as descripcion, M.debe, M.haber, M.saldodeudor, M.saldoacredor, M.activo, M.pasivo, M.perdidasnat, M.ganancianat, M.perdidasfun, M.gananciafun,T.cuentaF, T.totaldebe,T.totalhaber ,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) >0 THEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) ELSE 0 END as finaldeudor,
CASE WHEN coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0) <0 THEN -1 * (coalesce(T.totaldebe,0) - coalesce(T.totalhaber,0) + coalesce(M.debe,0) - coalesce(M.haber,0)) ELSE 0 END as finalacreedor,
T.ver_pas, T.ver_nat, T.ver_fun
from get_hoja_trabajo_detalle_registro($1,(substring($2::varchar,0,5)||'01')::integer,$3) AS M 
FULL JOIN (select O1.cuenta as cuentaF,
--sum(O1.saldodeudor) as totaldebe,
--sum(O1.saldoacredor) as totalhaber   from get_hoja_trabajo_detalle_registro($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
sum(O1.debe) as totaldebe,
sum(O1.haber) as totalhaber,
CASE WHEN sum(O1.activo)> 0 or sum(O1.pasivo) >0 THEN 1 ELSE 0 END as ver_pas,
CASE WHEN sum(O1.perdidasnat)> 0 or sum(O1.ganancianat) >0 THEN 1 ELSE 0 END as ver_nat,
CASE WHEN sum(O1.perdidasfun)> 0 or sum(O1.gananciafun) >0 THEN 1 ELSE 0 END as ver_fun

   from get_hoja_trabajo_detalle_registro($1,(substring($2::varchar,0,5)||'00')::integer,(substring($2::varchar,0,5)||'00')::integer ) as O1
group by O1.cuenta) AS T on T.cuentaF = M.cuenta 
left join account_account aa_f on aa_f.code = T.cuentaF order by cuenta) RES) AS X;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_reporte_hoja_registro(boolean, integer, integer)
  OWNER TO openpg;


-- Function: public.get_venta_1(boolean, integer, integer)

-- DROP FUNCTION public.get_venta_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_venta_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(comprobante character varying, am_id integer, clasifica character varying, base_impuesto numeric, monto numeric, record_sale character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
 SELECT account_move.dec_reg_nro_comprobante AS comprobante,
    account_move.id AS am_id,
    account_tax_code.name AS clasifica,
      CASE WHEN $1 THEN 
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END ) ELSE account_move_line.tax_amount END AS base_impuesto,
    CASE WHEN $1 THEN 
  (CASE
            WHEN account_journal.type::text = 'sale_refund'::text THEN account_move_line.currency_rate_it*account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.currency_rate_it*account_move_line.tax_amount
        END)
    ELSE
        (CASE
            WHEN account_journal.type::text = 'sale_refund'::text THEN account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.tax_amount
        END)
       END AS monto,
       
    account_tax_code.record_sale
   FROM account_move
     JOIN account_move_line ON account_move.id = account_move_line.move_id
     JOIN account_journal ON account_move_line.journal_id = account_journal.id AND account_move.journal_id = account_journal.id
     JOIN account_period ON account_move.period_id = account_period.id AND account_move.period_id = account_period.id
     LEFT JOIN it_type_document ON account_move_line.type_document_id = it_type_document.id AND account_move.dec_mod_type_document_id = it_type_document.id AND account_move.dec_reg_type_document_id = it_type_document.id
     LEFT JOIN res_partner ON account_move.partner_id = res_partner.id AND account_move_line.partner_id = res_partner.id
     LEFT JOIN it_type_document_partner ON res_partner.type_document_id = it_type_document_partner.id
     JOIN account_tax_code ON account_move_line.tax_code_id = account_tax_code.id
  WHERE account_journal.register_sunat::text = '2'::text and periodo_num(account_period.name) >= $2 and periodo_num(account_period.name) <= $3
  and account_move.state != 'draft'
  ORDER BY account_move.dec_reg_nro_comprobante;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_venta_1(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_venta_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_venta_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_venta_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(am_id integer, "1" numeric, "2" numeric, "3" numeric, "4" numeric, "5" numeric, "6" numeric, "7" numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
 SELECT crosstab.am_id,
    crosstab."1",
    crosstab."2",
    crosstab."3",
    crosstab."4",
    crosstab."5",
    crosstab."6",
    crosstab."7"
   FROM crosstab('SELECT v1.am_id ,v1.record_sale,
  sum(v1.monto) as monto FROM get_venta_1(' || $1 || ',' || $2 || ','|| $3 || ') as v1
  GROUP BY v1.am_id, v1.record_sale
  ORDER BY 1,2,3'::text, '  select m from generate_series(1,7) m'::text) crosstab(am_id integer, "1" numeric, "2" numeric, "3" numeric, "4" numeric, "5" numeric, "6" numeric, "7" numeric);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_venta_1_1(boolean, integer, integer)
  OWNER TO openpg;





-- Function: public.get_venta_1_1_1(boolean, integer, integer)

-- DROP FUNCTION public.get_venta_1_1_1(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_venta_1_1_1(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(id bigint, am_id integer, periodo character varying, libro character varying, voucher character varying, fechaemision date, fechavencimiento date, tipodocumento character varying, serie text, numero text, tipodoc character varying, numdoc character varying, partner character varying, valorexp numeric, baseimp numeric, inafecto numeric, exonerado numeric, isc numeric, igv numeric, otros numeric, total numeric, divisa character varying, tipodecambio numeric, fechad date, numeromodd character varying, fechadm date, tipodocmod character varying, anio character varying, seriemod text, numeromod text) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
SELECT row_number() OVER () AS id,
    t.am_id,
    t.periodo,
    t.libro,
    t.voucher,
    t.fechaemision,
    t.fechavencimiento,
    t.tipodocumento,
    t.serie,
    t.numero,
    t.tipodoc,
    t.numdoc,
    t.partner,
    t.valorexp,
    t.baseimp,
    t.inafecto,
    t.exonerado,
    t.isc,
    t.igv,
    t.otros,
    t.total,
    t.divisa,
    t.tipodecambio,
    t.fechad,
    t.numeromodd,
    t.fechadm,
    t.tipodocmod,
    t.anio,
    t.seriemod,
    t.numeromod
   FROM ( SELECT pr.am_id,
            ap.name AS periodo,
            aj.code AS libro,
            am.name AS voucher,
            am.date AS fechaemision,
            am.com_det_date_maturity AS fechavencimiento,
            itd.code AS tipodocumento,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN ''::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, 0, "position"(am.dec_reg_nro_comprobante::text, '-'::text))
                END AS serie,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN am.dec_reg_nro_comprobante::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, "position"(am.dec_reg_nro_comprobante::text, '-'::text) + 1)
                END AS numero,
            itdp.code AS tipodoc,
            rp.type_number AS numdoc,
            rp.name AS partner,
            pr.valorexp,
            pr.baseimp,
            pr.inafecto,
            pr.exonerado,
            pr.isc,
            pr.igv,
            pr.otros,
            pr.total,
            rc.name AS divisa,

            CASE WHEN $1 THEN am.com_det_type_change
            ELSE
            CASE WHEN rc.name = 'USD' THEN am.com_det_type_change ELSE Null::numeric END END AS tipodecambio,
            am.com_det_date AS fechad,
            am.com_det_number AS numeromodd,
            apercep.fecha AS fechadm,
            itd2.code AS tipodocmod,
                CASE
                    WHEN itd.id = mp.export_document_id THEN date_part('year'::text, am.date)::character varying(50)
                    ELSE ''::character varying(50)
                END AS anio,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN ''::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, 0, "position"(am.dec_mod_nro_comprobante::text, '-'::text))
                END AS seriemod,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN am.dec_mod_nro_comprobante::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, "position"(am.dec_mod_nro_comprobante::text, '-'::text) + 1)
                END AS numeromod
           FROM ( SELECT vst_reg_ventas_1_1.am_id,
                    sum(vst_reg_ventas_1_1."1") AS valorexp,
                    sum(vst_reg_ventas_1_1."2") AS baseimp,
                    sum(vst_reg_ventas_1_1."3") AS inafecto,
                    sum(vst_reg_ventas_1_1."4") AS exonerado,
                    sum(vst_reg_ventas_1_1."5") AS isc,
                    sum(vst_reg_ventas_1_1."6") AS otros,
                    sum(vst_reg_ventas_1_1."7") AS igv,
                    COALESCE(sum(vst_reg_ventas_1_1."1"), 0::numeric) + COALESCE(sum(vst_reg_ventas_1_1."2"), 0::numeric) + COALESCE(sum(vst_reg_ventas_1_1."3"), 0::numeric) + COALESCE(sum(vst_reg_ventas_1_1."4"), 0::numeric) + COALESCE(sum(vst_reg_ventas_1_1."5"), 0::numeric) + COALESCE(sum(vst_reg_ventas_1_1."6"), 0::numeric) + COALESCE(sum(vst_reg_ventas_1_1."7"), 0::numeric) AS total
                   FROM get_venta_1_1($1,$2,$3) as vst_reg_ventas_1_1
                  GROUP BY vst_reg_ventas_1_1.am_id) pr
             JOIN account_move am ON am.id = pr.am_id
             JOIN account_journal aj ON aj.id = am.journal_id
             JOIN account_period ap ON ap.id = am.period_id
             LEFT JOIN it_type_document itd ON itd.id = am.dec_reg_type_document_id
             LEFT JOIN res_partner rp ON rp.id = am.partner_id
             LEFT JOIN it_type_document_partner itdp ON itdp.id = rp.type_document_id
             LEFT JOIN res_currency rc ON rc.id = am.com_det_currency
             LEFT JOIN account_invoice ai ON ai.move_id = am.id
             LEFT JOIN account_perception apercep ON apercep.father_invoice_id = ai.id
             LEFT JOIN account_invoice ai_hijo ON ai_hijo.supplier_invoice_number = apercep.comprobante and ai.type = ai_hijo.type
             LEFT JOIN it_type_document itd2 ON itd2.id = am.dec_mod_type_document_id
             CROSS JOIN main_parameter mp
          WHERE (ai_hijo.id IN ( SELECT min(ai_hijo_1.id) AS min
                   FROM account_move am_1
                     JOIN account_invoice ai_1 ON ai_1.move_id = am_1.id
                     JOIN account_perception adr_1 ON adr_1.father_invoice_id = ai_1.id
                     JOIN account_invoice ai_hijo_1 ON ai_hijo_1.supplier_invoice_number = adr_1.comprobante and ai_1.type = ai_hijo_1.type
                  GROUP BY ai_1.id)) OR ai_hijo.* IS NULL
          ORDER BY ap.name, aj.code, am.name) t;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_venta_1_1_1(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_venta_1_1_ebidence(boolean, integer, integer)

-- DROP FUNCTION public.get_venta_1_1_ebidence(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_venta_1_1_ebidence(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(aml_id integer, "1" numeric, "2" numeric, "3" numeric, "4" numeric, "5" numeric, "6" numeric, "7" numeric) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
 SELECT v1.aml_id,
  CASE WHEN v1.record_sale = '1' then v1.monto else 0 end,
  CASE WHEN v1.record_sale = '2' then v1.monto else 0 end,
  CASE WHEN v1.record_sale = '3' then v1.monto else 0 end,
  CASE WHEN v1.record_sale = '4' then v1.monto else 0 end,
  CASE WHEN v1.record_sale = '5' then v1.monto else 0 end,
  CASE WHEN v1.record_sale = '6' then v1.monto else 0 end,
  CASE WHEN v1.record_sale = '7' then v1.monto else 0 end
   FROM get_venta_1_ebidence( $1 , $2 , $3 ) as v1
  ORDER BY aml_id;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_venta_1_1_ebidence(boolean, integer, integer)
  OWNER TO openpg;



-- Function: public.get_venta_1_ebidence(boolean, integer, integer)

-- DROP FUNCTION public.get_venta_1_ebidence(boolean, integer, integer);

CREATE OR REPLACE FUNCTION public.get_venta_1_ebidence(
    IN has_currency boolean,
    IN periodo_ini integer,
    IN periodo_fin integer)
  RETURNS TABLE(comprobante character varying, aml_id integer, clasifica character varying, base_impuesto numeric, monto numeric, record_sale character varying) AS
$BODY$
BEGIN

IF $3 is Null THEN
    $3 := $2;
END IF;

RETURN QUERY 
 SELECT account_move.dec_reg_nro_comprobante AS comprobante,
    account_move_line.id AS aml_id,
    account_tax_code.name AS clasifica,
      CASE WHEN $1 THEN 
      ( CASE WHEN coalesce(account_move_line.currency_rate_it,1) = 0 THEN account_move_line.tax_amount
      ELSE account_move_line.tax_amount/ coalesce(account_move_line.currency_rate_it,1) END ) ELSE account_move_line.tax_amount END AS base_impuesto,
    CASE WHEN $1 THEN 
  (CASE
            WHEN account_journal.type::text = 'sale_refund'::text THEN account_move_line.currency_rate_it*account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.currency_rate_it*account_move_line.tax_amount
        END)
    ELSE
        (CASE
            WHEN account_journal.type::text = 'sale_refund'::text THEN account_move_line.tax_amount * (-1)::numeric
            ELSE account_move_line.tax_amount
        END)
       END AS monto,
       
    account_tax_code.record_sale
   FROM account_move
     JOIN account_move_line ON account_move.id = account_move_line.move_id
     JOIN account_journal ON account_move_line.journal_id = account_journal.id AND account_move.journal_id = account_journal.id
     JOIN account_period ON account_move.period_id = account_period.id AND account_move.period_id = account_period.id
     LEFT JOIN it_type_document ON account_move_line.type_document_id = it_type_document.id AND account_move.dec_mod_type_document_id = it_type_document.id AND account_move.dec_reg_type_document_id = it_type_document.id
     LEFT JOIN res_partner ON account_move.partner_id = res_partner.id AND account_move_line.partner_id = res_partner.id
     LEFT JOIN it_type_document_partner ON res_partner.type_document_id = it_type_document_partner.id
     JOIN account_tax_code ON account_move_line.tax_code_id = account_tax_code.id
  WHERE account_journal.register_sunat::text = '2'::text and periodo_num(account_period.name) >= $2 and periodo_num(account_period.name) <= $3
  and account_move.state != 'draft'
  ORDER BY account_move.dec_reg_nro_comprobante;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_venta_1_ebidence(boolean, integer, integer)
  OWNER TO openpg;




-- Function: public.get_rotation(integer, character varying, character varying)

-- DROP FUNCTION public.get_rotation(integer, character varying, character varying);

CREATE OR REPLACE FUNCTION public.get_rotation(
    producto integer,
    rd character varying,
    td character varying)
  RETURNS SETOF numeric AS
$BODY$
BEGIN
RETURN QUERY
    select sum(sm.product_qty)
     from stock_move sm
     left join stock_picking sp on sm.picking_id = sp.id
     left join stock_picking_type spt on sp.picking_type_id = spt.id
     left join stock_location sls on spt.default_location_src_id = sls.id
     left join stock_location sld on spt.default_location_dest_id = sld.id
     where
         sm.product_id = $1 and
         sls.usage = 'internal' and
         fecha_num(sm.date::date) between fecha_num($2::date) and fecha_num($3::date);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.get_rotation(integer, character varying, character varying)
  OWNER TO openpg;



-- Function: public.rep_banco_con_saldo_inicial(boolean, integer)

-- DROP FUNCTION public.rep_banco_con_saldo_inicial(boolean, integer);

CREATE OR REPLACE FUNCTION public.rep_banco_con_saldo_inicial(
    IN has_currency boolean,
    IN periodo integer)
  RETURNS TABLE(cuentacode character varying, cuentaname character varying, fecha date, glosa character varying, periodo character varying, debe numeric, haber numeric, partner character varying, num_interno character varying, tipo_pago character varying, voucher character varying, libro character varying, acc_number character varying, bank_bic character varying, ordenamiento integer) AS
$BODY$
SELECT 
  aa.code AS cuentacode,
  aa.name AS cuentaname,
  aml.date AS fecha,
  aml.name as glosa,
  ap.name AS periodo,
  CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
  CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
  --aml.debit AS debe,
  --aml.credit AS haber,
  public.res_partner.name as partner,
  am.ref as Num_interno,
  itd.code as Tipo_pago,
  am.name as Voucher,
  aj.code as Libro,
  aa.cashbank_number as acc_number,
  aa.cashbank_financy as bank_bic,
  1 as ordenamiento
FROM
  account_move_line aml
  INNER JOIN account_move am ON (am.id = aml.move_id)
  INNER JOIN account_period ap ON (ap.id = am.period_id)
  INNER JOIN account_journal aj on (aj.id = am.journal_id)
  INNER JOIN account_account aa ON (aa.id = aml.account_id)
  LEFT OUTER JOIN public.res_partner ON (am.partner_id = public.res_partner.id)
  LEFT JOIN it_type_document itd ON itd.id = aml.type_document_id
WHERE
  aa.type::text = 'liquidity' ::text AND 
  periodo_num(ap.name) = $2 AND 
  aa.check_liquidity = true
  and am.state != 'draft'

UNION ALL


SELECT 
  aa.code AS cuentacode,
  aa.name AS cuentaname,
  inicio_periodo(periodo_string($2)) AS fecha,
  'SALDO INICIAL' as glosa,
  Null::varchar AS periodo,
  CASE WHEN $1 
  THEN CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN abs(sum(aml.debit_me) - sum(aml.credit_me)) ELSE 0 END
  ELSE CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN abs(sum(aml.debit) - sum(aml.credit)) ELSE 0 END END AS debe,
  CASE WHEN $1 
  THEN CASE WHEN (sum(aml.debit) - sum(aml.credit)) <0 THEN abs(sum(aml.debit_me)-sum(aml.credit_me)) ELSE 0 END
  ELSE CASE WHEN (sum(aml.debit) - sum(aml.credit)) <0 THEN abs(sum(aml.debit)-sum(aml.credit)) ELSE 0 END END AS haber,
  --CASE WHEN $1 THEN sum(aml.debit_me) ELSE sum(aml.debit) END AS debe,
  --CASE WHEN $1 THEN sum(aml.credit_me) ELSE sum(aml.credit) END AS haber,

  Null::varchar as partner,
  Null::varchar as Num_interno,
  Null::varchar as Tipo_pago,
  Null::varchar as Voucher,
  Null::varchar as Libro,
  aa.cashbank_number as acc_number,
  aa.cashbank_financy as bank_bic,
  0 as ordenamiento
FROM
  account_move_line aml
  INNER JOIN account_move am ON (am.id = aml.move_id)
  INNER JOIN account_period ap ON (ap.id = am.period_id)
  INNER JOIN account_account aa ON (aa.id = aml.account_id)
  LEFT OUTER JOIN public.res_partner ON (am.partner_id = public.res_partner.id)
  
WHERE
  aa.type::text = 'liquidity' ::text AND 
  periodo_num(ap.name) < $2 AND 
  aa.check_liquidity = true
  and am.state != 'draft'
 GROUP BY aa.code, aa.name, aa.cashbank_number, aa.cashbank_financy
order by cuentacode, ordenamiento, fecha
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.rep_banco_con_saldo_inicial(boolean, integer)
  OWNER TO openpg;



-- Function: public.rep_caja_con_saldo_inicial(boolean, integer)

-- DROP FUNCTION public.rep_caja_con_saldo_inicial(boolean, integer);

CREATE OR REPLACE FUNCTION public.rep_caja_con_saldo_inicial(
    IN has_currency boolean,
    IN periodo integer)
  RETURNS TABLE(numopelibro character varying, cuentacode character varying, cuentaname character varying, fecha date, glosa character varying, periodo character varying, debe numeric, haber numeric, ordenamiento integer) AS
$BODY$
    SELECT
      
      am.name as numopelibro,
      'Cuenta: ' || aa.code || ' ' || aa.name  AS cuentacode,
      aa.name AS cuentaname,
      aml.date AS fecha,
      aml.name as glosa,
      ap.name AS periodo,
      CASE WHEN $1 THEN aml.debit_me ELSE aml.debit END AS debe,
      CASE WHEN $1 THEN aml.credit_me ELSE aml.credit END AS haber,
      1 as ordenamiento
    FROM
      account_move_line aml
      INNER JOIN account_period ap ON (ap.id = aml.period_id)
      INNER JOIN account_move am ON (am.id = aml.move_id)
      INNER JOIN account_account aa ON (aa.id = aml.account_id)
    WHERE
      aa.type::text = 'liquidity' ::text  AND 
      periodo_num(ap.name) = $2 AND 
      coalesce(aa.check_liquidity,false) = false
      and am.state != 'draft'

    UNION ALL
    SELECT 
    Null::varchar  as numopelibro,
        'Cuenta: ' || aa.code || ' ' || aa.name  AS cuentacode,
                    Null::varchar AS cuentaname,
        Null::date AS fecha,
        'Saldo Inicial' AS glosa,
                    periodo_string($2) AS periodo,
                   CASE WHEN $1 
      THEN CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN abs(sum(aml.debit_me) - sum(aml.credit_me)) ELSE 0 END
      ELSE CASE WHEN sum(aml.debit) - sum(aml.credit) >0 THEN abs(sum(aml.debit) - sum(aml.credit)) ELSE 0 END END AS debe,
      CASE WHEN $1 
      THEN CASE WHEN (sum(aml.debit) - sum(aml.credit)) <0 THEN abs(sum(aml.debit_me)-sum(aml.credit_me)) ELSE 0 END
      ELSE CASE WHEN (sum(aml.debit) - sum(aml.credit)) <0 THEN abs(sum(aml.debit)-sum(aml.credit)) ELSE 0 END END AS haber,
                    0 as ordenamiento
      FROM
      account_move_line aml
      INNER JOIN account_period ap ON (ap.id = aml.period_id)
      INNER JOIN account_move am ON (am.id = aml.move_id)
      INNER JOIN account_account aa ON (aa.id = aml.account_id)

    WHERE
      aa.type::text = 'liquidity' ::text  AND 
      periodo_num(ap.name) < $2 AND 
      am.state != 'draft' and
      coalesce(aa.check_liquidity,false) = false
      GROUP BY aa.code,aa.name

                ORDER BY cuentacode,ordenamiento,fecha

               
$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.rep_caja_con_saldo_inicial(boolean, integer)
  OWNER TO openpg;



-- Function: public.rep_stock_saldo(integer)

-- DROP FUNCTION public.rep_stock_saldo(integer);

CREATE OR REPLACE FUNCTION public.rep_stock_saldo(IN fechalimite integer)
  RETURNS TABLE(product_id integer, codigo character varying, producto character varying, entrada numeric, salida numeric, saldo numeric, porvender numeric, cosumido numeric, producido numeric, saldores numeric) AS
$BODY$

set time zone 'UTC';
select product_id,codigo,producto,
sum(entrada) as entrada,
sum(salida) as salida,
sum(saldo) as saldo,
sum(porvender) as porvender,
sum(cosumido) as consumido,
sum(producido) as producido,
sum(saldores ) as saldores
from
(
select
case when o1.product_id is not null then o1.product_id
else
 case when o2.product_id is not null then o2.product_id
 else
  case when o3.product_id is not null then o3.product_id
  else o4.product_id end
 end
end as product_id,

case when o1.codigo is not null then o1.codigo
else
 case when o2.codigo is not null then o2.codigo
 else
  case when o3.codigo is not null then o3.codigo
  else o4.codigo end
 end
end as codigo,

case when o1.producto is not null then o1.producto
else
 case when o2.producto is not null then o2.producto
 else
  case when o3.producto is not null then o3.producto
  else o4.producto end
 end
end as producto,
case when o1.entrada is not null then o1.entrada else 0 end as entrada,
case when o1.salida is not null then o1.salida else 0 end as salida,
case when o1.saldo is not null then o1.saldo else 0 end as saldo,
case when o2.reservado is not null then o2.reservado else 0 end as porvender,
case when o3.produciendo is not null then o3.produciendo else 0 end as cosumido,
case when o4.producido is not null then o4.producido else 0 end as producido,
coalesce(o1.saldo,0)-coalesce(o2.reservado,0)+coalesce(o4.producido,0) as saldores
from (
select
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(entrada,0)) as entrada ,sum(coalesce(salida,0)) as salida,
sum(coalesce(entrada,0)) -sum(coalesce(salida,0)) as saldo
from (
select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage = 'internal' and active= true) then stock_move.product_qty else 0 end as salida,
case when stock_move.location_dest_id in (select id from stock_location where usage = 'internal' and active= true) then stock_move.product_qty else 0 end as entrada
from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
where (stock_move.location_id in (select id from stock_location where usage = 'internal' and active= true) or stock_move.location_dest_id in (select id from stock_location where usage = 'internal' and active= true))
and stock_move.state='done'
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date) <=$1
) l
group by name_template,product_id,
default_code
order by name_template) o1
full join
(

select
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(salida,0)) as reservado
from (
select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('customer') and active= true)  then stock_move.product_qty else 0 end as salida
from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
where (stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('customer') and active=true ))
and stock_picking.state not in ('draft','done','cancel','confirmed')
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date)  <=$1
) l
group by name_template,product_id,
default_code
order by name_template

) o2 on o1.product_id = o2.product_id


full join
(
select
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(salida,0)) as produciendo
from
(

select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true)
 and stock_move.location_dest_id in (select id from stock_location where usage in ('production') and active= true) 
 then stock_move.product_qty else 0 end as salida

from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
where (stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('production') and active= true)  )
and stock_picking.state not in ('draft','done','cancel','confirmed')
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date)  <=$1
) l
group by name_template,product_id,
default_code
order by name_template

) o3 on o1.product_id = o3.product_id






full join
(
select
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(salida,0)) as producido
from
(

select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage in ('production') and active= true)
 and stock_move.location_dest_id in (select id from stock_location where usage in ('internal') and active= true) 
 then stock_move.product_qty else 0 end as salida

from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
where (stock_move.location_id in (select id from stock_location where usage in ('production') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('internal') and active= true)  )
and stock_picking.state not in ('draft','done','cancel')
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date)  <=$1
) l
group by name_template,product_id,
default_code
order by name_template

) o4 on o1.product_id = o4.product_id) y
group by product_id,codigo,producto
order by producto



$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.rep_stock_saldo(integer)
  OWNER TO openpg;




-- Function: public.rep_stock_saldo(integer, integer[], integer[])

-- DROP FUNCTION public.rep_stock_saldo(integer, integer[], integer[]);

CREATE OR REPLACE FUNCTION public.rep_stock_saldo(
    IN fechalimite integer,
    IN productos integer[],
    IN almacenes integer[])
  RETURNS TABLE(almacen character varying, almacen_name character varying, product_id integer, codigo character varying, producto character varying, entrada numeric, salida numeric, saldo numeric, porvender numeric, cosumido numeric, producido numeric, saldores numeric) AS
$BODY$

set time zone 'UTC';
select 
almacen,
almacen as almacen_name,
product_id,
codigo,producto,
sum(entrada) as entrada,
sum(salida) as salida,
sum(saldo) as saldo,
sum(porvender) as porvender,
sum(cosumido) as consumido,
sum(producido) as producido,
sum(saldores ) as saldores
from
(
select

case when o1.almacen is not null then o1.almacen
else
 case when o2.almacen is not null then o2.almacen
 else
  case when o3.almacen is not null then o3.almacen
  else o4.almacen end
 end
end as almacen,


case when o1.product_id is not null then o1.product_id
else
 case when o2.product_id is not null then o2.product_id
 else
  case when o3.product_id is not null then o3.product_id
  else o4.product_id end
 end
end as product_id,

case when o1.codigo is not null then o1.codigo
else
 case when o2.codigo is not null then o2.codigo
 else
  case when o3.codigo is not null then o3.codigo
  else o4.codigo end
 end
end as codigo,

case when o1.producto is not null then o1.producto
else
 case when o2.producto is not null then o2.producto
 else
  case when o3.producto is not null then o3.producto
  else o4.producto end
 end
end as producto,
case when o1.entrada is not null then o1.entrada else 0 end as entrada,
case when o1.salida is not null then o1.salida else 0 end as salida,
case when o1.saldo is not null then o1.saldo else 0 end as saldo,
case when o2.reservado is not null then o2.reservado else 0 end as porvender,
case when o3.produciendo is not null then o3.produciendo else 0 end as cosumido,
case when o4.producido is not null then o4.producido else 0 end as producido,
coalesce(o1.saldo,0)-coalesce(o2.reservado,0)+coalesce(o4.producido,0) as saldores
from (
select
almacen,
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(entrada,0)) as entrada ,sum(coalesce(salida,0)) as salida,
sum(coalesce(entrada,0)) -sum(coalesce(salida,0)) as saldo
from (
select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage = 'internal' and active= true) then stock_move.product_qty else 0 end as salida,
case when stock_move.location_dest_id in (select id from stock_location where usage = 'internal' and active= true) then stock_move.product_qty else 0 end as entrada,
case when swo.id is not null then swo.name else swd.name end as almacen
from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
left join stock_location slo on stock_move.location_id = slo.id
left join stock_warehouse swo on slo.id = swo.lot_stock_id
left join stock_location sld on stock_move.location_dest_id = sld.id
left join stock_warehouse swd on sld.id = swd.lot_stock_id
where 
--(stock_move.location_id in (select id from stock_location where usage = 'internal' and active= true) or stock_move.location_dest_id in (select id from stock_location where usage = 'internal' and active= true))
stock_move.state='done'
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date) <=$1
and stock_move.product_id  = ANY($2)
and (stock_move.location_dest_id = ANY($3) or stock_move.location_id = ANY($3))
) l
group by almacen,name_template,product_id,
default_code
order by name_template) o1
full join
(

select
almacen,
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(salida,0)) as reservado
from (
select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('customer') and active= true)  then stock_move.product_qty else 0 end as salida,
stock_warehouse.name as almacen
from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
inner join stock_location on stock_move.location_id = stock_location.id
inner join stock_warehouse on stock_location.id = stock_warehouse.lot_stock_id
where (stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('customer') and active=true ))
and stock_picking.state not in ('draft','done','cancel','confirmed','partially_available')
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date)  <=$1
and stock_move.product_id  = ANY($2)
and stock_move.location_id = ANY($3)
) l
group by almacen,name_template,product_id,
default_code
order by name_template

) o2 on o1.product_id = o2.product_id


full join
(
select
almacen,
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(salida,0)) as produciendo
from
(

select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true)
 and stock_move.location_dest_id in (select id from stock_location where usage in ('production') and active= true) 
 then stock_move.product_qty else 0 end as salida,
stock_warehouse.name as almacen
from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
inner join stock_location on stock_move.location_id = stock_location.id
inner join stock_warehouse on stock_location.id = stock_warehouse.lot_stock_id
where (stock_move.location_id in (select id from stock_location where usage in ('internal') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('production') and active= true)  )
and stock_picking.state not in ('draft','done','cancel','confirmed')
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date)  <=$1
and stock_move.product_id  = ANY($2)
and stock_move.location_id = ANY($3)
) l
group by almacen,name_template,product_id,
default_code
order by name_template

) o3 on o1.product_id = o3.product_id

full join
(
select
almacen,
product_id ,
default_code as codigo,
name_template as producto,
sum(coalesce(salida,0)) as producido
from
(

select
stock_move.product_id,
product_product.name_template,
product_product.default_code,
stock_picking.date,
case when stock_move.location_id in (select id from stock_location where usage in ('production') and active= true)
 and stock_move.location_dest_id in (select id from stock_location where usage in ('internal') and active= true) 
 then stock_move.product_qty else 0 end as salida,
stock_warehouse.name as almacen
from stock_move
inner join product_product on stock_move.product_id = product_product.id
left join stock_picking on stock_move.picking_id = stock_picking.id
inner join stock_location on stock_move.location_id = stock_location.id
inner join stock_warehouse on stock_location.id = stock_warehouse.lot_stock_id
where (stock_move.location_id in (select id from stock_location where usage in ('production') and active= true) and stock_move.location_dest_id in (select id from stock_location where usage in ('internal') and active= true)  )
and stock_picking.state not in ('draft','done','cancel')
and fecha_num((stock_picking.date at time zone 'GMT-5') ::date)  <=$1
and stock_move.product_id  = ANY($2)
and stock_move.location_id = ANY($3)
) l
group by almacen,name_template,product_id,
default_code
order by name_template

) o4 on o1.product_id = o4.product_id) y
group by almacen,product_id,codigo,producto
order by producto



$BODY$
  LANGUAGE sql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION public.rep_stock_saldo(integer, integer[], integer[])
  OWNER TO openpg;



  

  -- View: public.vst_ebi_compras_am

-- DROP VIEW public.vst_ebi_compras_am;

CREATE OR REPLACE VIEW public.vst_ebi_compras_am AS 
 SELECT compra.id,
    compra.am_id,
    compra.periodo,
    compra.libro,
    compra.voucher,
    compra.fechaemision,
    compra.fechavencimiento,
    compra.tipodocumento,
    compra.serie,
    compra.numero,
    compra.tdp,
    compra.ruc,
    compra.razonsocial,
    compra.bioge,
    compra.biogeng,
    compra.biong,
    compra.cng,
    compra.isc,
    compra.igva,
    compra.igvb,
    compra.igvc,
    compra.otros,
    compra.total,
    compra.comprobante,
    compra.moneda,
    compra.tc,
    compra.fechad,
    compra.numerod,
    compra.fechadm,
    compra.td,
    compra.anio,
    compra.seried,
    compra.numerodd,
    aml.name AS producto,
    aml.quantity,
        CASE
            WHEN atc.record_shop::text = ANY (ARRAY['1'::character varying::text, '2'::character varying::text, '3'::character varying::text]) THEN aml.debit - aml.credit
            ELSE 0::numeric
        END AS baseimp_l,
        CASE
            WHEN atc.record_shop::text = ANY (ARRAY['1'::character varying::text, '2'::character varying::text, '3'::character varying::text]) THEN 0.18 * (aml.debit - aml.credit)
            ELSE 0::numeric
        END AS igv,
        CASE
            WHEN atc.record_shop::text = '4'::text THEN aml.debit - aml.credit
            ELSE 0::numeric
        END AS nogravado,
    res_company.id AS company_id,
    res_company.name AS company
   FROM get_compra_1_1_1(false, 0, 219001) compra(id, am_id, periodo, libro, voucher, fechaemision, fechavencimiento, tipodocumento, serie, numero, tdp, ruc, razonsocial, bioge, biogeng, biong, cng, isc, igva, igvb, igvc, otros, total, comprobante, moneda, tc, fechad, numerod, fechadm, td, anio, seried, numerodd)
     JOIN account_period ap ON ap.name::text = compra.periodo::text
     JOIN account_move am ON am.id = compra.am_id
     JOIN account_move_line aml ON aml.move_id = am.id
     JOIN res_company ON am.company_id = res_company.id
     JOIN account_tax_code atc ON atc.id = aml.tax_code_id AND (atc.record_shop::text = ANY (ARRAY['4'::character varying::text, '2'::character varying::text, '1'::character varying::text, '3'::character varying::text]))
     LEFT JOIN res_partner rptpv ON rptpv.id = am.partner_id
     LEFT JOIN account_invoice ai1 ON ai1.move_id = am.id
     LEFT JOIN account_period ap1 ON ap1.id = am.periodo_ajuste_modificacion_ple_venta
  WHERE periodo_num(ap.code) >= periodo_num('00/2017'::character varying) AND periodo_num(ap.code) <= periodo_num('02/2517'::character varying);

ALTER TABLE public.vst_ebi_compras_am
  OWNER TO openpg;




-- View: public.vst_venta_ebidence

-- DROP VIEW public.vst_venta_ebidence;

CREATE OR REPLACE VIEW public.vst_venta_ebidence AS 
 SELECT date_part('year'::text, t.fechaemision) AS anio,
    date_part('month'::text, t.fechaemision) AS mes,
    date_part('day'::text, t.fechaemision) AS dia,
    t.periodo,
    t.fechavencimiento AS vence,
    t.tipodocumento AS tipodoc,
    ((t.serie || '-'::text) || t.numero)::character varying AS numdoc,
    t.numdoc AS ruc,
    t.partner AS proveedor,
    t.valorexp AS valor_exportacion,
    t.baseimp AS imponible,
        CASE
            WHEN t.producto IS NOT NULL THEN t.producto
            ELSE t.glosa
        END AS producto,
    t.cantidad
   FROM ( SELECT pr.aml_id,
            aml.name AS glosa,
            pp.name_template AS producto,
            aml.quantity AS cantidad,
            ap.name AS periodo,
            aj.code AS libro,
            am.name AS voucher,
            am.date AS fechaemision,
            am.com_det_date_maturity AS fechavencimiento,
            itd.code AS tipodocumento,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN ''::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, 0, "position"(am.dec_reg_nro_comprobante::text, '-'::text))
                END AS serie,
                CASE
                    WHEN "position"(am.dec_reg_nro_comprobante::text, '-'::text) = 0 THEN am.dec_reg_nro_comprobante::text
                    ELSE "substring"(am.dec_reg_nro_comprobante::text, "position"(am.dec_reg_nro_comprobante::text, '-'::text) + 1)
                END AS numero,
            itdp.code AS tipodoc,
            rp.type_number AS numdoc,
            rp.name AS partner,
            pr.valorexp,
            pr.baseimp,
            pr.inafecto,
            pr.exonerado,
            pr.isc,
            pr.igv,
            pr.otros,
            pr.total,
            rc.name AS divisa,
                CASE
                    WHEN false THEN am.com_det_type_change
                    ELSE
                    CASE
                        WHEN rc.name::text = 'USD'::text THEN am.com_det_type_change
                        ELSE NULL::numeric
                    END
                END AS tipodecambio,
            am.com_det_date AS fechad,
            am.com_det_number AS numeromodd,
            am.dec_mod_fecha AS fechadm,
            itd2.code AS tipodocmod,
                CASE
                    WHEN itd.id = mp.export_document_id THEN date_part('year'::text, am.date)::character varying(50)
                    ELSE ''::character varying(50)
                END AS anio,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN ''::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, 0, "position"(am.dec_mod_nro_comprobante::text, '-'::text))
                END AS seriemod,
                CASE
                    WHEN "position"(am.dec_mod_nro_comprobante::text, '-'::text) = 0 THEN am.dec_mod_nro_comprobante::text
                    ELSE "substring"(am.dec_mod_nro_comprobante::text, "position"(am.dec_mod_nro_comprobante::text, '-'::text) + 1)
                END AS numeromod
           FROM ( SELECT vst_reg_ventas_1_1.aml_id,
                    vst_reg_ventas_1_1."1" AS valorexp,
                    vst_reg_ventas_1_1."2" AS baseimp,
                    vst_reg_ventas_1_1."3" AS inafecto,
                    vst_reg_ventas_1_1."4" AS exonerado,
                    vst_reg_ventas_1_1."5" AS isc,
                    vst_reg_ventas_1_1."6" AS otros,
                    vst_reg_ventas_1_1."7" AS igv,
                    COALESCE(vst_reg_ventas_1_1."1", 0::numeric) + COALESCE(vst_reg_ventas_1_1."2", 0::numeric) + COALESCE(vst_reg_ventas_1_1."3", 0::numeric) + COALESCE(vst_reg_ventas_1_1."4", 0::numeric) + COALESCE(vst_reg_ventas_1_1."5", 0::numeric) + COALESCE(vst_reg_ventas_1_1."6", 0::numeric) + COALESCE(vst_reg_ventas_1_1."7", 0::numeric) AS total
                   FROM get_venta_1_1_ebidence(false, 0, 258401) vst_reg_ventas_1_1(aml_id, "1", "2", "3", "4", "5", "6", "7")
                  ORDER BY vst_reg_ventas_1_1.aml_id) pr
             JOIN account_move_line aml ON aml.id = pr.aml_id
             LEFT JOIN product_product pp ON pp.id = aml.product_id
             JOIN account_move am ON am.id = aml.move_id
             JOIN account_journal aj ON aj.id = am.journal_id
             JOIN account_period ap ON ap.id = am.period_id
             LEFT JOIN it_type_document itd ON itd.id = am.dec_reg_type_document_id
             LEFT JOIN res_partner rp ON rp.id = am.partner_id
             LEFT JOIN it_type_document_partner itdp ON itdp.id = rp.type_document_id
             LEFT JOIN res_currency rc ON rc.id = am.com_det_currency
             LEFT JOIN account_invoice ai ON ai.move_id = am.id
             LEFT JOIN it_type_document itd2 ON itd2.id = am.dec_mod_type_document_id
             CROSS JOIN main_parameter mp
          ORDER BY ap.name, aj.code, am.name) t
  WHERE t.valorexp <> 0::numeric OR t.baseimp <> 0::numeric;

ALTER TABLE public.vst_venta_ebidence
  OWNER TO openpg;




-- View: detalle_simple_fisico_total_d

-- DROP VIEW detalle_simple_fisico_total_d;

CREATE OR REPLACE VIEW detalle_simple_fisico_total_d AS 
 SELECT row_number() OVER () AS id,
    mn.u AS almacen,
    mn.p AS producto,
    mn.s AS saldo
   FROM ( SELECT sl.id AS u,
            pp.id AS p,
            x.saldo AS s
           FROM ( SELECT t.product_id,
                    t.ubicacion,
                    sum(t.saldo) AS saldo
                   FROM ( SELECT vst_stock_move_final.product_id,
                            vst_stock_move_final.location_id AS ubicacion,
                            - vst_stock_move_final.product_qty AS saldo
                           FROM vst_stock_move_final
                          WHERE vst_stock_move_final.date::date >= '2017-01-01'::date
                        UNION ALL
                         SELECT vst_stock_move_final.product_id,
                            vst_stock_move_final.location_dest_id AS ubicacion,
                            vst_stock_move_final.product_qty AS saldo
                           FROM vst_stock_move_final
                          WHERE vst_stock_move_final.date::date >= '2017-01-01'::date) t
                  GROUP BY t.product_id, t.ubicacion) x
             JOIN stock_location sl ON sl.id = x.ubicacion
             JOIN product_product pp ON pp.id = x.product_id
          WHERE sl.usage::text = 'internal'::text) mn
  ORDER BY mn.u, mn.p, mn.s;

ALTER TABLE detalle_simple_fisico_total_d
  OWNER TO openpg;
