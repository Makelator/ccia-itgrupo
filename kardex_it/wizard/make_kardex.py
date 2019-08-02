# -*- coding: utf-8 -*-
from odoo.tools.misc import DEFAULT_SERVER_DATETIME_FORMAT
import time
import odoo.addons.decimal_precision as dp
from openerp.osv import osv
import base64
from odoo import models, fields, api
import codecs
values = {}

class make_kardex(models.TransientModel):
	_name = "make.kardex"
	period_id = fields.Many2one('account.period','Periodo')
	fini= fields.Date('Fecha inicial',required=True)
	ffin= fields.Date('Fecha final',required=True)
	products_ids=fields.Many2many('product.product','rel_wiz_kardex','product_id','kardex_id')
	location_ids=fields.Many2many('stock.location','rel_kardex_location','location_id','kardex_id','Ubicacion',required=True)
	allproducts=fields.Boolean('Todos los productos',default=True)
	destino = fields.Selection([('csv','CSV'),('crt','Pantalla')],'Destino')
	check_fecha = fields.Boolean('Editar Fecha')
	alllocations = fields.Boolean('Todos los almacenes',default=True)

	fecha_ini_mod = fields.Date('Fecha Inicial')
	fecha_fin_mod = fields.Date('Fecha Final')
	analizador = fields.Boolean('Analizador',compute="get_analizador")

	@api.multi
	def get_analizador(self):
		print "contexto",self.env.context
		if 'tipo' in self.env.context:
			if self.env.context['tipo'] == 'valorado':
				self.analizador = True
			else:
				self.analizador = False
		else:
			self.analizador = False

	_defaults={
		'destino':'crt',
		'check_fecha': False,
		'allproducts': True,
		'alllocations': True,
	}

	@api.onchange('fecha_ini_mod')
	def onchange_fecha_ini_mod(self):
		self.fini = self.fecha_ini_mod


	@api.onchange('fecha_fin_mod')
	def onchange_fecha_fin_mod(self):
		self.ffin = self.fecha_fin_mod

	@api.model
	def default_get(self, fields):
		res = super(make_kardex, self).default_get(fields)
		import datetime
		fecha_hoy = str(datetime.datetime.now())[:10]
		fecha_inicial = fecha_hoy[:4] + '-01-01'
		res.update({'fecha_ini_mod':fecha_inicial})
		res.update({'fecha_fin_mod':fecha_hoy})
		res.update({'fini':fecha_inicial})
		res.update({'ffin':fecha_hoy})

		#locat_ids = self.pool.get('stock.location').search(cr, uid, [('usage','in',('internal','inventory','transit','procurement','production'))])
		locat_ids = self.env['stock.location'].search([('usage','in',('internal','inventory','transit','procurement','production'))])
		locat_ids = [elemt.id for elemt in locat_ids]
		res.update({'location_ids':[(6,0,locat_ids)]})
		return res

	@api.onchange('alllocations')
	def onchange_alllocations(self):
		if self.alllocations == True:
			locat_ids = self.env['stock.location'].search( [('usage','in',('internal','inventory','transit','procurement','production'))] )
			self.location_ids = [(6,0,locat_ids.ids)]
		else:
			self.location_ids = [(6,0,[])]

	@api.onchange('period_id')
	def onchange_period_id(self):
		self.fini = self.period_id.date_start
		self.ffin = self.period_id.date_stop



	@api.model
	def do_csv_resume(self,cr,uid,ids,context=None):
		data = self.read(cr, uid, ids, [], context=context)[0]
		cad=""
		prods= self.pool.get('product.product').search(cr,uid,[])
		locat = self.pool.get('stock.location').search(cr,uid,[])

		lst_products  = prods
		lst_locations = data['location_ids']
		productos='{'
		almacenes='{'
		date_ini=data['fini']
		date_fin=data['ffin']

		for producto in lst_products:
			productos=productos+str(producto)+','
		productos=productos[:-1]+'}'
		for location in lst_locations:
			almacenes=almacenes+str(location)+','
		almacenes=almacenes[:-1]+'}'
		# raise osv.except_osv('Alertafis',[almacenes,productos])
		if data['destino']=='csv':

			cadf=self.make_cad_res(cr,uid,date_ini,date_fin, productos , almacenes,'csv')
			cr.execute(cadf)
			f = open('e:/PLES_ODOO/kardex_cta.csv', 'rb')
			sfs_obj = self.pool.get('repcontab_base.sunat_file_save')
			vals = {
				'output_name': 'kardex_cta.csv',
				'output_file': base64.encodestring(''.join(f.readlines())),
			}
			mod_obj = self.pool.get('ir.model.data')
			act_obj = self.pool.get('ir.actions.act_window')
			sfs_id = self.pool.get('export.file.save').create(cr,uid,vals)
			result = {}
			view_ref = mod_obj.get_object_reference(cr,uid,'account_contable_book_it', 'export_file_save_action')
			view_id = view_ref and view_ref[1] or False
			result = act_obj.read( cr,uid,[view_id],context )
			return {
			    "type": "ir.actions.act_window",
			    "res_model": "export.file.save",
			    "views": [[False, "form"]],
			    "res_id": sfs_id,
			    "target": "new",
			}
		else:

			obj_cad= self.pool.get('kardex.resume')
			lst = obj_cad.search(cr,uid,[])
			obj_cad.unlink(cr,uid,lst)
			#cadf=self.make_cad_res(cr,uid,date_ini,date_fin, productos , almacenes,'crt')


			cadf  = """select A2.cuenta, coalesce(A1.debe,0) as saldo, A2.debit as contable,coalesce(A1.debe,0) - A2.debit as dif    from (
			select "Cuenta producto",sum("Ingreso Valorado.") as debe,round(sum("Salida Valorada"),2) as haber,
			sum("Ingreso Valorado.") as saldo

			from (select
			get_kardex_v.almacen AS "Almacen",
			get_kardex_v.categoria as "Categoria",
			get_kardex_v.name_template as "Producto",
			get_kardex_v.fecha as "Fecha",
			get_kardex_v.ctanalitica as "Cta. Analitica",
			get_kardex_v.serial as "Serie",
			get_kardex_v.nro as "Nro. Documento",
			get_kardex_v.operation_type as "Tipo de operacion",
			get_kardex_v.name as "Proveedor",
			get_kardex_v.ingreso as "Ingreso Fisico",
			get_kardex_v.salida as "Salida Fisico",
			get_kardex_v.saldof as "Saldo Fisico",
			get_kardex_v.debit as "Ingreso Valorado.",
			get_kardex_v.credit as "Salida Valorada",
			get_kardex_v.cadquiere as "Costo adquisicion",
			get_kardex_v.saldov as "Saldo valorado",
			get_kardex_v.cprom as "Costo promedio",
			--get_kardex_v.cost_account as "Cuenta de costo",
			get_kardex_v.account_invoice as "Cuenta factura",
			get_kardex_v.product_account as "Cuenta producto",
			default_code as "Codigo",unidad as "Unidad",
			get_kardex_v.product_id,
			--get_kardex_v.documento_partner,
			get_kardex_v.ubicacion_origen
							from get_kardex_v("""+ date_ini.replace("-","") + "," + date_fin.replace("-","") + ",'" + productos + """'::INT[], '""" + almacenes + """'::INT[])
			order by correlativovisual
			) t
			inner join stock_location origen on t.ubicacion_origen = origen.id
			where  origen.usage = 'supplier' -- and "Periodo" = '""" + str(data['period_id'][1]) + """'
			group by "Cuenta producto"
			order by "Cuenta producto" ) as A1
				full join (
				select account_period.code as "Periodo",
				account_account.code || ' - ' || account_account.name as cuenta,
				sum(account_move_line.debit ) as debit
				from account_move
				inner join account_move_line on account_move.id = account_move_line.move_id
				inner join account_account on account_move_line.account_id = account_account.id
				left join res_partner on account_move_line.partner_id = res_partner.id
				--inner join product_product on account_move_line.product_id = product_product.id
				inner join account_period on account_move.period_id = account_period.id
				where (account_account.code like '20%' or account_account.code like '25%' or account_account.code like '24%' or account_account.code like '26%' ) and account_period.id = """+ str(data['period_id'][0])+"""
				group by
				account_period.code,
				account_account.code || ' - ' || account_account.name
				) as A2 on A1."Cuenta producto" = A2.cuenta
				"""


			#raise osv.except_osv('Alertafis',cadf)
			cr.execute(cadf)
			dicf=cr.dictfetchall()
			for data_c in dicf:
				obj_cad.create(cr,uid,{'periodo':data['period_id'][1],'cta':data_c['cuenta'],'monto':data_c['saldo'],'contable':data_c['contable'],'dif':data_c['dif']})




			view_ref = self.pool.get('ir.model.data').get_object_reference(cr, uid, 'kardex', 'view_kardex_resume_tree')
			view_id = view_ref and view_ref[1] or False
			search_ref = self.pool.get('ir.model.data').get_object_reference(cr, uid, 'kardex', 'view_kardex_resume_filter')

			return {
						'domain':[('dif','!=',0)],
						'type': 'ir.actions.act_window',
						'name': 'Kardex: Resumen X Cta. ',
						'res_model': 'kardex.resume',
						'view_mode': 'tree',
						'view_type': 'form',
						'target': 'current',
						'search_view_id':search_ref[1],
					}



	@api.model
	def kardex_vs_account_line(self):
		#data = self.read(cr, uid, ids, [], context=context)[0]
		data = self.read()
		cad=""
		#prods= self.pool.get('product.product').search(cr,uid,[])
		prods= self.env['product.product'].search([])
		#locat = self.pool.get('stock.location').search(cr,uid,[])
		locat= self.env['stock.location'].search([])
		locat = [s.id for s in locat]

		#lst_products  = prods
		prods = [s.id for s in prods]
		lst_locations = data['location_ids']
		productos='{'
		almacenes='{'
		date_ini=data['fini']
		date_fin=data['ffin']

		for producto in lst_products:
			productos=productos+str(producto)+','
		productos=productos[:-1]+'}'
		for location in lst_locations:
			almacenes=almacenes+str(location)+','
		almacenes=almacenes[:-1]+'}'
		# raise osv.except_osv('Alertafis',[almacenes,productos])
		#obj_cad= self.pool.get('kardex.vs.account.line')
		obj_cad= self.env['kardex.vs.account.line'].search([])

		lst = obj_cad.search(cr,uid,[])
		obj_cad.unlink(cr,uid,lst)

		# cadf=self.make_cad_res(cr,uid,date_ini,date_fin, productos , almacenes,'crt')
		# raise osv.except_osv('Alertafis',cadf)

		cadf  = """select CASE WHEN A2.cuenta is not null THEN A2.cuenta ELSE A1."Cuenta producto" END as cuenta,
			CASE WHEN A2.proveedor is not null THEN A2.proveedor ELSE A1."Proveedor" END as proveedor , CASE WHEN A2.dec_reg_nro_comprobante is not null THEN A2.dec_reg_nro_comprobante ELSE A1."Factura" END as dec_reg_nro_comprobante
 			, CASE WHEN A2.name_template is not null THEN A2.name_template ELSE A1."Producto" END as name_template, coalesce(A1.debe,0) as montokardex, coalesce(A2.debit,0) as monto, coalesce(A1.debe,0) - coalesce(A2.debit,0) as diference    from (
			select "Cuenta producto",sum("Ingreso Valorado.") as debe,round(sum("Salida Valorada"),2) as haber,
			sum("Ingreso Valorado.") as saldo,"Periodo",
			case when "Serie" is not null then "Serie"||'-'||"Nro. Documento" else "Nro. Documento" end as "Factura",
			"Producto","Proveedor",product_id
			from (select
			get_kardex_v.almacen AS "Almacen",
			get_kardex_v.categoria as "Categoria",
			get_kardex_v.name_template as "Producto",
			get_kardex_v.fecha as "Fecha",
			get_kardex_v.periodo as "Periodo",
			get_kardex_v.ctanalitica as "Cta. Analitica",
			get_kardex_v.serial as "Serie",
			get_kardex_v.nro as "Nro. Documento",
			get_kardex_v.operation_type as "Tipo de operacion",
			get_kardex_v.name as "Proveedor",
			get_kardex_v.ingreso as "Ingreso Fisico",
			get_kardex_v.salida as "Salida Fisico",
			get_kardex_v.saldof as "Saldo Fisico",
			get_kardex_v.debit as "Ingreso Valorado.",
			get_kardex_v.credit as "Salida Valorada",
			get_kardex_v.cadquiere as "Costo adquisicion",
			get_kardex_v.saldov as "Saldo valorado",
			get_kardex_v.cprom as "Costo promedio",
			--get_kardex_v.cost_account as "Cuenta de costo",
			get_kardex_v.account_invoice as "Cuenta factura",
			get_kardex_v.product_account as "Cuenta producto",
			default_code as "Codigo",unidad as "Unidad",
			get_kardex_v.product_id,
			--get_kardex_v.documento_partner,
			get_kardex_v.ubicacion_origen
							from get_kardex_v("""+date_ini.replace("-","") + "," + date_fin.replace("-","")+ ",'" + productos + """'::INT[], '""" + almacenes + """'::INT[])
			order by correlativovisual
			) t
			inner join stock_location origen on t.ubicacion_origen = origen.id
			where --"Cuenta factura" is not null and "Cuenta factura"!='' and
			origen.usage = 'supplier' -- and "Periodo" = '""" + str(data['period_id'][1]) + """'
			group by "Cuenta producto","Periodo","Serie", "Nro. Documento","Producto","Proveedor","Producto",product_id,documento_partner
			order by "Periodo","Proveedor","Serie", "Nro. Documento","Producto" ) as A1
				full join (
				select account_period.code,
				account_account.code || ' - ' || account_account.name as cuenta,
				account_move.dec_reg_nro_comprobante,
				CASE WHEN product_product.name_template is not null THEN product_product.name_template ELSE 'Nulo' END as name_template,
				sum(account_move_line.debit ) as debit,
				res_partner.name as proveedor,
				account_move_line.product_id,res_partner.nro_documento
				from account_move
				inner join account_move_line on account_move.id = account_move_line.move_id
				inner join account_account on account_move_line.account_id = account_account.id
				left join res_partner on account_move_line.partner_id = res_partner.id
				left join product_product on account_move_line.product_id = product_product.id
				inner join account_period on account_move.period_id = account_period.id
				where (account_account.code like '20%' or account_account.code like '25%' or account_account.code like '24%' or account_account.code like '26%' ) and account_period.id = """+ str(data['period_id'][0])+"""
				group by
				account_period.code,
				account_account.code || ' - ' || account_account.name ,
				account_move.dec_reg_nro_comprobante,
				product_product.name_template,
				account_move_line.product_id,
				res_partner.name,res_partner.nro_documento ) as A2 on A1."Factura" = A2.dec_reg_nro_comprobante and A1.product_id = A2.product_id
				and A1.documento_partner = A2.type_number and A1."Cuenta producto" = A2.cuenta
				"""
		cr.execute(cadf)
		valores = cr.dictfetchall()
		for data_c in valores:
			obj_cad.create(cr,uid,
				{
				'cta':data_c['cuenta'],
				'periodo':data['period_id'][1],
				'proveedor':data_c['proveedor'],
				'factura':data_c['dec_reg_nro_comprobante'],
				'producto':data_c['name_template'],
				'montokardex':data_c['montokardex'],
				'contable':data_c['monto'],
				'dif':data_c['diference']})

		#view_ref = self.pool.get('ir.model.data').get_object_reference(cr, uid, 'kardex', 'view_kardex_vs_account_line_tree')
		view_ref = self.env['ir.model.data'].get_object_reference('kardex', 'view_kardex_vs_account_line_tree')
		view_id = view_ref and view_ref[1] or False
		#search_ref = self.pool.get('ir.model.data').get_object_reference(cr, uid, 'kardex', 'view_kardex_vs_account_line_filter')
		search_ref = self.env['ir.model.data'].get_object_reference('kardex', 'view_kardex_vs_account_line_filter')

		return {
						'domain':[('dif','!=',0)],
					'type': 'ir.actions.act_window',
					'name': 'Kardex: Comprar lineas',
					'res_model': 'kardex.vs.account.line',
					'view_mode': 'tree',
					'view_type': 'form',
					'target': 'current',
					'search_view_id':search_ref[1],
				}




	@api.multi
	def do_csvtoexcel(self):
		cad = ""

		s_prod = [-1,-1,-1]
		s_loca = [-1,-1,-1]
		if self.alllocations == True:
			locat_ids = self.env['stock.location'].search( [('usage','in',('internal','inventory','transit','procurement','production'))] )
			lst_locations = locat_ids.ids
		else:
			lst_locations = self.location_ids.ids
		lst_products  = self.products_ids.ids
		productos='{'
		almacenes='{'
		date_ini=self.fini
		date_fin=self.ffin
		if self.allproducts:
			lst_products = self.env['product.product'].with_context(active_test=False).search([]).ids
			print lst_products

		else:
			lst_products = self.products_ids.ids

		if len(lst_products) == 0:
			raise osv.except_osv('Alerta','No existen productos seleccionados')

		for producto in lst_products:
			productos=productos+str(producto)+','
			s_prod.append(producto)
		productos=productos[:-1]+'}'
		for location in lst_locations:
			almacenes=almacenes+str(location)+','
			s_loca.append(location)
		almacenes=almacenes[:-1]+'}'
		# raise osv.except_osv('Alertafis',[almacenes,productos])

		if self.env.context['tipo']=='valorado':

			import io
			from xlsxwriter.workbook import Workbook
			output = io.BytesIO()
			########### PRIMERA HOJA DE LA DATA EN TABLA
			#workbook = Workbook(output, {'in_memory': True})

			direccion = self.env['main.parameter'].search([])[0].dir_create_file
			workbook = Workbook(direccion +'kardex_producto.xlsx')
			worksheet = workbook.add_worksheet("Kardex")
			bold = workbook.add_format({'bold': True})
			bold.set_font_size(8)
			normal = workbook.add_format()
			boldbord = workbook.add_format({'bold': True})
			boldbord.set_border(style=2)
			boldbord.set_align('center')
			boldbord.set_align('vcenter')
			boldbord.set_text_wrap()
			boldbord.set_font_size(8)
			boldbord.set_bg_color('#DCE6F1')

			especial1 = workbook.add_format({'bold': True})
			especial1.set_align('center')
			especial1.set_align('vcenter')
			especial1.set_text_wrap()
			especial1.set_font_size(15)

			numbertres = workbook.add_format({'num_format':'0.000'})
			numberdos = workbook.add_format({'num_format':'0.00'})
			numberseis = workbook.add_format({'num_format':'0.000000'})
			numberseis.set_font_size(8)
			numberocho = workbook.add_format({'num_format':'0.00000000'})
			numberocho.set_font_size(8)
			bord = workbook.add_format()
			bord.set_border(style=1)
			bord.set_font_size(8)
			numberdos.set_border(style=1)
			numberdos.set_font_size(8)
			numbertres.set_border(style=1)
			numberseis.set_border(style=1)
			numberocho.set_border(style=1)
			numberdosbold = workbook.add_format({'num_format':'0.00','bold':True})
			numberdosbold.set_font_size(8)
			x= 10
			tam_col = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
			tam_letra = 1.2
			import sys
			reload(sys)
			sys.setdefaultencoding('iso-8859-1')

			worksheet.merge_range(1,5,1,10, "KARDEX VALORADO", especial1)
			worksheet.write(2,0,'FECHA INICIO:',bold)
			worksheet.write(3,0,'FECHA FIN:',bold)

			worksheet.write(2,1,self.fini)
			worksheet.write(3,1,self.ffin)
			import datetime

			worksheet.merge_range(8,0,9,0, u"Fecha Alm.",boldbord)
			worksheet.merge_range(8,1,9,1, u"Fecha",boldbord)
			worksheet.merge_range(8,2,9,2, u"Tipo",boldbord)
			worksheet.merge_range(8,3,9,3, u"Serie",boldbord)
			worksheet.merge_range(8,4,9,4, u"Número",boldbord)
			worksheet.merge_range(8,5,9,5, u"Guía de remisión",boldbord)

			worksheet.merge_range(8,6,9,6, u"Doc. Almacen",boldbord)
			worksheet.merge_range(8,7,9,7, u"RUC",boldbord)
			worksheet.merge_range(8,8,9,8, u"Empresa",boldbord)

			worksheet.merge_range(8,9,9,9, u"T. OP.",boldbord)

			worksheet.merge_range(8,10,9,10, u"Código",boldbord)
			worksheet.merge_range(8,11,9,11, u"Producto",boldbord)
			worksheet.merge_range(8,12,9,12, u"Unidad",boldbord)

			worksheet.merge_range(8,13,8,14, u"Ingreso",boldbord)
			worksheet.write(9,13, "Cantidad",boldbord)
			worksheet.write(9,14, "Costo",boldbord)
			worksheet.merge_range(8,15,8,16, u"Salida",boldbord)
			worksheet.write(9,15, "Cantidad",boldbord)
			worksheet.write(9,16, "Costo",boldbord)
			worksheet.merge_range(8,17,8,18, u"Saldo",boldbord)
			worksheet.write(9,17, "Cantidad",boldbord)
			worksheet.write(9,18, "Costo",boldbord)

			worksheet.merge_range(8,19,9,19, u"Costo Adquisición",boldbord)
			worksheet.merge_range(8,20,9,20, "Costo Promedio",boldbord)

			worksheet.merge_range(8,21,9,21, "Ubicacion Origen",boldbord)
			worksheet.merge_range(8,22,9,22, "Ubicacion Destino",boldbord)
			worksheet.merge_range(8,23,9,23, "Almacen",boldbord)


			self.env.cr.execute("""
				 select

				get_kardex_v.fecha_albaran as "Fecha Alb.",
				get_kardex_v.fecha as "Fecha",
				get_kardex_v.type_doc as "T. Doc.",
				get_kardex_v.serial as "Serie",
				get_kardex_v.nro as "Nro. Documento",
				get_kardex_v.stock_doc as "Nro. Documento",
				get_kardex_v.doc_partner as "Nro Doc. Partner",
				get_kardex_v.name as "Proveedor",
				get_kardex_v.operation_type as "Tipo de operacion",
				get_kardex_v.name_template as "Producto",
				get_kardex_v.unidad as "Unidad",
				get_kardex_v.ingreso as "Ingreso Fisico",
				round(get_kardex_v.debit,6) as "Ingreso Valorado.",
				get_kardex_v.salida as "Salida Fisico",
				round(get_kardex_v.credit,6) as "Salida Valorada",
				get_kardex_v.saldof as "Saldo Fisico",
				round(get_kardex_v.saldov,6) as "Saldo valorado",
				round(get_kardex_v.cadquiere,6) as "Costo adquisicion",
				round(get_kardex_v.cprom,6) as "Costo promedio",
					get_kardex_v.origen as "Origen",
					get_kardex_v.destino as "Destino",
				get_kardex_v.almacen AS "Almacen",
				coalesce(product_product.default_code,product_template.default_code) as "Codigo",
				stock_picking.numberg as "Guia de Remision"


				from get_kardex_v("""+ str(date_ini).replace('-','') + "," + str(date_fin).replace('-','') + ",'" + productos + """'::INT[], '""" + almacenes + """'::INT[])
				left join stock_move on get_kardex_v.stock_moveid = stock_move.id
				left join product_product on product_product.id = stock_move.product_id
				left join product_template on product_template.id = product_product.product_tmpl_id
				left join stock_picking on stock_move.picking_id = stock_picking.id
				
				order by get_kardex_v.correlativovisual
			""")

			ingreso1= 0
			ingreso2= 0
			salida1= 0
			salida2= 0

			for line in self.env.cr.fetchall():
				worksheet.write(x,0,line[0] if line[0] else '' ,bord )
				worksheet.write(x,1,line[1] if line[1] else '' ,bord )
				worksheet.write(x,2,line[2] if line[2] else '' ,bord )
				worksheet.write(x,3,line[3] if line[3] else '' ,bord )
				worksheet.write(x,4,line[4] if line[4] else '' ,bord )
				worksheet.write(x,5,line[23] if line[23] else '' ,bord )
				worksheet.write(x,6,line[5] if line[5] else '' ,bord )
				worksheet.write(x,7,line[6] if line[6] else '' ,bord )
				worksheet.write(x,8,line[7] if line[7] else '' ,bord )
				worksheet.write(x,9,line[8] if line[8] else '' ,bord )
				worksheet.write(x,10,line[22] if line[22] else '' ,bord )

				worksheet.write(x,11,line[9] if line[9] else 0 ,numberdos )
				worksheet.write(x,12,line[10] if line[10] else 0 ,numberdos )
				worksheet.write(x,13,line[11] if line[11] else 0 ,numberdos )
				worksheet.write(x,14,line[12] if line[12] else 0 ,numberdos )
				worksheet.write(x,15,line[13] if line[13] else 0 ,numberdos )
				worksheet.write(x,16,line[14] if line[14] else 0 ,numberdos )
				worksheet.write(x,17,line[15] if line[15] else 0 ,numberseis )
				worksheet.write(x,18,line[16] if line[16] else 0 ,numberocho )

				worksheet.write(x,19,line[17] if line[17] else '' ,bord )
				worksheet.write(x,20,line[18] if line[18] else '' ,bord )
				worksheet.write(x,21,line[19] if line[19] else '' ,bord )
				worksheet.write(x,22,line[20] if line[20] else '' ,bord )
				worksheet.write(x,23,line[21] if line[21] else '' ,bord )

				ingreso1 += line[11] if line[11] else 0
				ingreso2 +=line[12] if line[12] else 0
				salida1 +=line[13] if line[13] else 0
				salida2 += line[14] if line[14] else 0

				x = x +1

			tam_col = [11,11,5,5,7,7,5,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11]

			worksheet.write(x,12,'TOTALES:' ,bold )
			worksheet.write(x,13,ingreso1 ,numberdosbold )
			worksheet.write(x,14,ingreso2 ,numberdosbold )
			worksheet.write(x,15,salida1 ,numberdosbold )
			worksheet.write(x,16,salida2 ,numberdosbold )

			worksheet.set_column('A:A', tam_col[0])
			worksheet.set_column('B:B', tam_col[1])
			worksheet.set_column('C:C', tam_col[2])
			worksheet.set_column('D:D', tam_col[3])
			worksheet.set_column('E:E', tam_col[4])
			worksheet.set_column('F:F', tam_col[5])
			worksheet.set_column('G:G', tam_col[6])
			worksheet.set_column('H:H', tam_col[7])
			worksheet.set_column('I:I', tam_col[8])
			worksheet.set_column('J:J', tam_col[9])
			worksheet.set_column('K:K', tam_col[10])
			worksheet.set_column('L:L', tam_col[11])
			worksheet.set_column('M:M', tam_col[12])
			worksheet.set_column('N:N', tam_col[13])
			worksheet.set_column('O:O', tam_col[14])
			worksheet.set_column('P:P', tam_col[15])
			worksheet.set_column('Q:Q', tam_col[16])
			worksheet.set_column('R:R', tam_col[17])
			worksheet.set_column('S:S', tam_col[18])
			worksheet.set_column('T:Z', tam_col[19])

			workbook.close()

			f = open(direccion + 'kardex_producto.xlsx', 'rb')


			sfs_obj = self.pool.get('repcontab_base.sunat_file_save')
			vals = {
				'output_name': 'Kardex.xlsx',
				'output_file': base64.encodestring(''.join(f.readlines())),
			}

			mod_obj = self.env['ir.model.data']
			act_obj = self.env['ir.actions.act_window']
			sfs_id = self.env['export.file.save'].create(vals)
			result = {}
			#import pdb; pdb.set_trace()
			#view_ref = mod_obj.get_object_reference('account_contable_book_it', 'export_file_save_action')
			#view_id = view_ref and view_ref[1] or False
			#result = act_obj.read( [view_id] )
			print sfs_id

			#import os
			#os.system('c:\\eSpeak2\\command_line\\espeak.exe -ves-f1 -s 170 -p 100 "Se Realizo La exportación exitosamente Y A EDWARD NO LE GUSTA XDXDXDXDDDDDDDDDDDD" ')
			return {
			    "type": "ir.actions.act_window",
			    "res_model": "export.file.save",
			    "views": [[False, "form"]],
			    "res_id": sfs_id.id,
			    "target": "new",
			}
		else:


			import io
			from xlsxwriter.workbook import Workbook
			output = io.BytesIO()
			########### PRIMERA HOJA DE LA DATA EN TABLA
			#workbook = Workbook(output, {'in_memory': True})

			direccion = self.env['main.parameter'].search([])[0].dir_create_file
			workbook = Workbook(direccion +'kardex_producto.xlsx')
			worksheet = workbook.add_worksheet("Kardex")
			bold = workbook.add_format({'bold': True})
			bold.set_font_size(8)
			normal = workbook.add_format()
			boldbord = workbook.add_format({'bold': True})
			boldbord.set_border(style=2)
			boldbord.set_align('center')
			boldbord.set_align('vcenter')
			boldbord.set_text_wrap()
			boldbord.set_font_size(8)
			boldbord.set_bg_color('#DCE6F1')

			especial1 = workbook.add_format({'bold': True})
			especial1.set_align('center')
			especial1.set_align('vcenter')
			especial1.set_text_wrap()
			especial1.set_font_size(15)

			numbertres = workbook.add_format({'num_format':'0.000'})
			numberdos = workbook.add_format({'num_format':'0.00'})
			numberseis = workbook.add_format({'num_format':'0.000000'})
			numberseis.set_font_size(8)
			numberocho = workbook.add_format({'num_format':'0.00000000'})
			numberocho.set_font_size(8)
			bord = workbook.add_format()
			bord.set_border(style=1)
			bord.set_font_size(8)
			numberdos.set_border(style=1)
			numberdos.set_font_size(8)
			numbertres.set_border(style=1)
			numberseis.set_border(style=1)
			numberocho.set_border(style=1)
			numberdosbold = workbook.add_format({'num_format':'0.00','bold':True})
			numberdosbold.set_font_size(8)
			x= 10
			tam_col = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
			tam_letra = 1.2
			import sys
			reload(sys)
			sys.setdefaultencoding('iso-8859-1')

			worksheet.merge_range(1,5,1,10, "KARDEX FISICO", especial1)
			worksheet.write(2,0,'FECHA INICIO:',bold)
			worksheet.write(3,0,'FECHA FIN:',bold)

			worksheet.write(2,1,self.fini)
			worksheet.write(3,1,self.ffin)
			import datetime

			worksheet.merge_range(8,0,9,0, u"Ubicacion Origen",boldbord)
			worksheet.merge_range(8,1,9,1, u"Ubicacion Destino",boldbord)
			worksheet.merge_range(8,2,9,2, u"Almacen",boldbord)
			worksheet.merge_range(8,3,9,3, u"Tipo de Operación",boldbord)
			worksheet.merge_range(8,4,9,4, u"Categoria",boldbord)

			worksheet.merge_range(8,5,9,5, u"Producto",boldbord)
			worksheet.merge_range(8,6,9,6, u"Codigo P.",boldbord)
			worksheet.merge_range(8,7,9,7, u"Unidad",boldbord)

			worksheet.merge_range(8,8,9,8, u"Fecha",boldbord)

			worksheet.merge_range(8,9,9,9, u"Doc. Almacen",boldbord)

			worksheet.write(8,10, "Ingreso",boldbord)
			worksheet.write(9,10, "Cantidad",boldbord)
			worksheet.write(8,11, "Salida",boldbord)
			worksheet.write(9,11, "Cantidad",boldbord)
			worksheet.write(8,12, "Saldo",boldbord)
			worksheet.write(9,12, "Cantidad",boldbord)



			self.env.cr.execute("""

				select
origen.complete_name AS "Ubicación Origen",
destino.complete_name AS "Ubicación Destino",
almacen.complete_name AS "Almacén",
vstf.motivo_guia AS "Tipo de operación",
pc.name as "Categoria",
product_name.name as "Producto",
pp.default_code as "Codigo P.",
pu.name as "unidad",
vstf.fecha as "Fecha",
sp.name as "Doc. Almacén",
vstf.entrada as "Entrada",
vstf.salida as "Salida"
from
(
	select vst_kardex_fisico.date::date as fecha,vst_kardex_fisico.location_id as origen, vst_kardex_fisico.location_dest_id as destino, vst_kardex_fisico.location_dest_id as almacen, vst_kardex_fisico.product_qty as entrada, 0 as salida,vst_kardex_fisico.id  as stock_move,vst_kardex_fisico.guia as motivo_guia,vst_kardex_fisico.product_id,vst_kardex_fisico.estado from vst_kardex_fisico
join stock_move sm on sm.id = vst_kardex_fisico.id
join stock_picking sp on sm.picking_id = sp.id
join stock_location l_o on l_o.id = vst_kardex_fisico.location_id
join stock_location l_d on l_d.id = vst_kardex_fisico.location_dest_id
where ( (l_o.usage = 'internal' and l_o.usage = 'internal' and coalesce(sp.en_ruta,false) = false )  or ( l_o.usage != 'internal' or l_o.usage != 'internal' ) )
	union all
	select vst_kardex_fisico.date::date as fecha,vst_kardex_fisico.location_id as origen, vst_kardex_fisico.location_dest_id as destino, vst_kardex_fisico.location_id as almacen, 0 as entrada, vst_kardex_fisico.product_qty as salida,vst_kardex_fisico.id  as stock_move ,vst_kardex_fisico.guia as motivo_guia ,vst_kardex_fisico.product_id ,vst_kardex_fisico.estado from vst_kardex_fisico
) as vstf
inner join stock_location origen on origen.id = vstf.origen
inner join stock_location destino on destino.id = vstf.destino
inner join stock_location almacen on almacen.id = vstf.almacen
inner join product_product pp on pp.id = vstf.product_id
INNER JOIN ( SELECT pp.id,
               pt.name::text || COALESCE((' ('::text || string_agg(pav.name::text, ', '::text)) || ')'::text, ''::text) AS name
              FROM product_product pp
         JOIN product_template pt ON pt.id = pp.product_tmpl_id
    LEFT JOIN product_attribute_value_product_product_rel pavpp ON pavpp.product_product_id = pp.id
   LEFT JOIN product_attribute_value pav ON pav.id = pavpp.product_attribute_value_id
  GROUP BY pp.id, pt.name) product_name ON product_name.id = pp.id

inner join product_template pt on pt.id = pp.product_tmpl_id
inner join product_category pc on pc.id = pt.categ_id
inner join product_uom pu on pu.id = (CASE WHEN pt.unidad_kardex IS NOT NULL THEN pt.unidad_kardex else  pt.uom_id end )
inner join stock_move sm on sm.id = vstf.stock_move
inner join stock_picking sp on sp.id = sm.picking_id
left join purchase_order po on po.id = sp.po_id
where vstf.fecha >='""" +str(date_ini)+ """' and vstf.fecha <='""" +str(date_fin)+ """'
and vstf.product_id in """ +str(tuple(s_prod))+ """
and vstf.almacen in """ +str(tuple(s_loca))+ """
and vstf.estado = 'done'
and almacen.usage = 'internal'
order by
almacen.id,pp.id,vstf.fecha,vstf.entrada desc
			""")

			ingreso1= 0
			ingreso2= 0
			salida1= 0
			salida2= 0

			saldo = 0
			almacen = None
			producto = None
			for line in self.env.cr.fetchall():
				if almacen == None:
					almacen = (line[2] if line[2] else '')
					producto = (line[5] if line[5] else '')
					saldo = line[10] - line[11]
				elif almacen != (line[2] if line[2] else '') or producto != (line[5] if line[5] else ''):
					almacen = (line[2] if line[2] else '')
					producto = (line[5] if line[5] else '')
					saldo = line[10] - line[11]
				else:
					saldo = saldo + line[10] - line[11]

				worksheet.write(x,0,line[0] if line[0] else '' ,bord )
				worksheet.write(x,1,line[1] if line[1] else '' ,bord )
				worksheet.write(x,2,line[2] if line[2] else '' ,bord )
				worksheet.write(x,3,line[3] if line[3] else '' ,bord )
				worksheet.write(x,4,line[4] if line[4] else '' ,bord )
				worksheet.write(x,5,line[5] if line[5] else '' ,bord )
				worksheet.write(x,6,line[6] if line[6] else '' ,bord )
				worksheet.write(x,7,line[7] if line[7] else '' ,bord )
				worksheet.write(x,8,line[8] if line[8] else '' ,bord )
				worksheet.write(x,9,line[9] if line[9] else '' ,bord )
				worksheet.write(x,10,line[10] if line[10] else 0 ,numberdos )
				worksheet.write(x,11,line[11] if line[11] else 0 ,numberdos )
				worksheet.write(x,12,saldo ,numberdos )

				x = x +1

			tam_col = [11,11,5,5,7,5,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11]


			worksheet.set_column('A:A', tam_col[0])
			worksheet.set_column('B:B', tam_col[1])
			worksheet.set_column('C:C', tam_col[2])
			worksheet.set_column('D:D', tam_col[3])
			worksheet.set_column('E:E', tam_col[4])
			worksheet.set_column('F:F', tam_col[5])
			worksheet.set_column('G:G', tam_col[6])
			worksheet.set_column('H:H', tam_col[7])
			worksheet.set_column('I:I', tam_col[8])
			worksheet.set_column('J:J', tam_col[9])
			worksheet.set_column('K:K', tam_col[10])
			worksheet.set_column('L:L', tam_col[11])
			worksheet.set_column('M:M', tam_col[12])
			worksheet.set_column('N:N', tam_col[13])
			worksheet.set_column('O:O', tam_col[14])
			worksheet.set_column('P:P', tam_col[15])
			worksheet.set_column('Q:Q', tam_col[16])
			worksheet.set_column('R:R', tam_col[17])
			worksheet.set_column('S:S', tam_col[18])
			worksheet.set_column('T:Z', tam_col[19])

			workbook.close()


			f = open(direccion + 'kardex_producto.xlsx', 'rb')


			sfs_obj = self.pool.get('repcontab_base.sunat_file_save')
			vals = {
				'output_name': 'Kardex.xlsx',
				'output_file': base64.encodestring(''.join(f.readlines())),
			}

			sfs_id = self.env['export.file.save'].create(vals)

			#import os
			#os.system('c:\\eSpeak2\\command_line\\espeak.exe -ves-f1 -s 170 -p 100 "Se Realizo La exportación exitosamente Y A EDWARD NO LE GUSTA XDXDXDXDDDDDDDDDDDD" ')

			return {
			    "type": "ir.actions.act_window",
			    "res_model": "export.file.save",
			    "views": [[False, "form"]],
			    "res_id": sfs_id.id,
			    "target": "new",
			}

	@api.multi
	def do_csv(self):
		data = self.read()
		cad=""
		if data[0]['products_ids']==[]:
			if data[0]['allproducts']:
				if data[0]['allproducts']==False:
					raise osv.except_osv('Alerta','No existen productos seleccionados')
					return
				else:
					#prods= self.pool.get('product.product').search(cr,uid,[])
					lst_products  = self.env['product.product'].search([]).ids
			else:
				raise osv.except_osv('Alerta','No existen productos seleccionados')
				return
		else:
			lst_products  = data[0]['products_ids']

		s_prod = [-1,-1,-1]
		s_loca = [-1,-1,-1]

		lst_locations = data[0]['location_ids']
		productos='{0,'
		almacenes='{0,'
		date_ini=data[0]['fini']
		date_fin=data[0]['ffin']
		if 'allproducts' in data[0]:
			if data[0]['allproducts']:
				#lst_products  = self.pool.get('product.product').search(cr,uid,[])
				lst_products = self.env['product.product'].with_context(active_test=False).search([]).ids
			else:
				lst_products  = data[0]['products_ids']
		else:
			lst_products  = data[0]['products_ids']

		if 'alllocations' in data[0]:
			lst_locations = self.env['stock.location'].search([]).ids

		for producto in lst_products:
			productos=productos+str(producto)+','
			s_prod.append(producto)
		productos=productos[:-1]+'}'
		for location in lst_locations:
			almacenes=almacenes+str(location)+','
			s_loca.append(location)
		almacenes=almacenes[:-1]+'}'
		# raise osv.except_osv('Alertafis',[almacenes,productos])
		#print 'tipo',context['tipo']
		#direccionid = self.pool.get('main.parameter').search(cr,uid,[])[0]
		direccion = self.env['main.parameter'].search([])[0].dir_create_file
		#direccion=self.pool.get('main.parameter').browse(cr,uid,direccionid,context).dir_create_file
		if self._context['tipo']=='valorado':
			cadf=u"""
				copy (select
				origen.complete_name AS "Ubicación Origen",
				destino.complete_name AS "Ubicación Destino",
				substring(get_kardex_v.almacen,20) AS "Almacén",
				get_kardex_v.operation_type as "T. OP",
				get_kardex_v.categoria as "Categoria",
				get_kardex_v.default_code as "Codigo P.",
				get_kardex_v.unidad as "Uni.",
				get_kardex_v.name_template as "Producto",
				get_kardex_v.fecha_albaran as "Fecha Alb.",
				get_kardex_v.fecha as "Fecha",
				get_kardex_v.periodo as "Periodo",
				get_kardex_v.stock_doc as "Doc. Almacén",
				get_kardex_v.type_doc as "T. Doc.",
				get_kardex_v.serial as "Serie",
				get_kardex_v.nro as "Nro. Documento",
				get_kardex_v.name as "Proveedor",
				get_kardex_v.ingreso as "Ingreso",
				get_kardex_v.salida as "Salida",
				get_kardex_v.saldof as "Saldo F",
				get_kardex_v.cadquiere as "C.A.",
				get_kardex_v.debit as "Debe",
				get_kardex_v.credit as "Haber",
				get_kardex_v.saldov as "Saldo V.",
				get_kardex_v.cprom as "CP",
				--get_kardex_v.cost_account as "Cuenta de costo",
				get_kardex_v.account_invoice as "Cuenta factura",
				get_kardex_v.product_account as "Cuenta producto",
				get_kardex_v.ctanalitica as "Cta. Analitica",


				get_kardex_v.pedido_compra as "Pedido de Compra",
				get_kardex_v.licitacion as "Licitacion"
				from get_kardex_v("""+date_ini.replace("-","") + "," + date_fin.replace("-","") + ",'" + productos + """'::INT[], '""" + almacenes + """'::INT[])
				left join stock_location origen on get_kardex_v.ubicacion_origen = origen.id
				left join stock_location destino on get_kardex_v.ubicacion_destino  = destino.id
				order by get_kardex_v.correlativovisual
				) to '"""+direccion+"""kardex.csv'  WITH DELIMITER ',' CSV HEADER
				"""
		else:
			if self._context['tipo']=='fisico':
				cadf=u"""



				copy (select
origen.complete_name AS "Ubicación Origen",
destino.complete_name AS "Ubicación Destino",
almacen.complete_name AS "Almacén",
vstf.motivo_guia AS "Tipo de operación",
pc.name as "Categoria",
product_name.name as "Producto",
pt.default_code as "Codigo P.",
pu.name as "unidad",
vstf.fecha as "Fecha",
sp.name as "Doc. Almacén",
vstf.entrada as "Entrada",
vstf.salida as "Salida",
po.name as pedido_compra
from
(
	select date::date as fecha,location_id as origen, location_dest_id as destino, location_dest_id as almacen, product_qty as entrada, 0 as salida,id  as stock_move,guia as motivo_guia,product_id,estado from vst_kardex_fisico
join stock_move sm on sm.id = vst_kardex_fisico.id
join stock_picking sp on sm.picking_id = sp.id
join stock_location l_o on l_o.id = vst_kardex_fisico.location_id
join stock_location l_d on l_d.id = vst_kardex_fisico.location_dest_id
where ( (l_o.usage = 'internal' and l_o.usage = 'internal' and coalesce(sp.en_ruta,false) = false )  or ( l_o.usage != 'internal' or l_o.usage != 'internal' ) )

	union all
	select date::date as fecha, location_id as origen, location_dest_id as destino, location_id as almacen, 0 as entrada, product_qty as salida,id  as stock_move ,guia as motivo_guia ,product_id , estado from vst_kardex_fisico
) as vstf
inner join stock_location origen on origen.id = vstf.origen
inner join stock_location destino on destino.id = vstf.destino
inner join stock_location almacen on almacen.id = vstf.almacen
inner join product_product pp on pp.id = vstf.product_id
INNER JOIN ( SELECT pp.id,
               pt.name::text || COALESCE((' ('::text || string_agg(pav.name::text, ', '::text)) || ')'::text, ''::text) AS name
              FROM product_product pp
         JOIN product_template pt ON pt.id = pp.product_tmpl_id
    LEFT JOIN product_attribute_value_product_product_rel pavpp ON pavpp.product_product_id = pp.id
   LEFT JOIN product_attribute_value pav ON pav.id = pavpp.product_attribute_value_id
  GROUP BY pp.id, pt.name) product_name ON product_name.id = pp.id

inner join product_template pt on pt.id = pp.product_tmpl_id
inner join product_category pc on pc.id = pt.categ_id
inner join product_uom pu on pu.id = (CASE WHEN pt.unidad_kardex is not null then pt.unidad_kardex else  pt.uom_id END)
inner join stock_move sm on sm.id = vstf.stock_move
inner join stock_picking sp on sp.id = sm.picking_id
left join purchase_order po on po.id = sp.po_id
where vstf.fecha >='""" +str(date_ini)+ u"""' and vstf.fecha <='""" +str(date_fin)+ u"""'
and vstf.product_id in """ +str(tuple(s_prod))+ u"""
and vstf.almacen in """ +str(tuple(s_loca))+ u"""
and vstf.estado = 'done'
and almacen.usage = 'internal'
order by
almacen.id,pp.id,vstf.fecha,vstf.entrada desc


) to '"""+direccion+u"""kardex.csv'  WITH DELIMITER ',' CSV HEADER
				"""
			else:
				cadf="select * from get_kardex_fis_sumi("+date_ini.replace("-","") + "," + date_fin.replace("-","") + ",'" + productos + "'::INT[], '" + almacenes + "'::INT[]) order by location_id,product_id,fecha,esingreso,nro"
		# raise osv.except_osv('Alertafis',cadf)

		self.env.cr.execute(cadf)
		import gzip
		import shutil
		# E:\REPORTES/
		# with open(direccion+'kardex.csv', 'rb') as f_in, gzip.open(direccion+'kardex.csv.gz', 'wb') as f_out:
		#	shutil.copyfileobj(f_in, f_out)

		f = open(direccion+'kardex.csv', 'rb')


		#sfs_obj = self.pool.get('repcontab_base.sunat_file_save')
		#sfs_obj = self.env['repcontab_base.sunat_file_save']
		vals = {
			'output_name': 'kardex.csv',
			'output_file': base64.encodestring(''.join(f.readlines())),
		}

		mod_obj = self.env['ir.model.data']
		act_obj = self.env['ir.actions.act_window']
		#sfs_id = self.pool.get('export.file.save').create(cr,uid,vals)
		sfs_id = self.env['export.file.save'].create(vals)


		# result = {}
		# view_ref = mod_obj.get_object_reference('account_contable_book_it', 'export_file_save_action')
		# view_id = view_ref and view_ref[1] or False
		# result = act_obj.read([view_id])
		# print sfs_id.id



		#import os
		#os.system('c:\\eSpeak2\\command_line\\espeak.exe -ves-f1 -s 170 -p 100 "Se Realizo La exportación exitosamente Y A EDWARD NO LE GUSTA XDXDXDXDDDDDDDDDDDD" ')

		return {
		    "type": "ir.actions.act_window",
		    "res_model": "export.file.save",
		    "views": [[False, "form"]],
		    "res_id": sfs_id.id,
		    "target": "new",
		}
