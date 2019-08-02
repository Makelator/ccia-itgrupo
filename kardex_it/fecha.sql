CREATE OR REPLACE FUNCTION public.fecha_num(date)
  RETURNS integer AS
$BODY$
    SELECT to_char($1, 'YYYYMMDD')::integer;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.fecha_num(date)
  OWNER TO odoo10;