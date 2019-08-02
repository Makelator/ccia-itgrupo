# -*- coding: utf-8 -*-

from openerp import models, fields, api
from openerp.osv import osv
import base64

class kardex_product_export(models.Model):
	_name = 'kardex.product.export'
	
	fecha_inicio = fields.Date('Fecha Inicio')
	fecha_final = fields.Date('Fecha Inicio') 
	ubicaciones = fields.Many2many('stock.location','location_rel_kardex_product_export','location_id','kardex_product_id','Ubicaciones')


	check_fecha = fields.Boolean('Editar Fecha')
	alllocations = fields.Boolean('Todos los almacenes',default=True)

	fecha_ini_mod = fields.Date('Fecha Inicial')
	fecha_fin_mod = fields.Date('Fecha Final')


	_defaults={
		'check_fecha': False,
		'alllocations': True,
	}
	
	@api.onchange('fecha_ini_mod')
	def onchange_fecha_ini_mod(self):
		self.fecha_inicio = self.fecha_ini_mod


	@api.onchange('fecha_fin_mod')
	def onchange_fecha_fin_mod(self):
		self.fecha_final = self.fecha_fin_mod

	@api.model
	def default_get(self, fields):
		res = super(kardex_product_export, self).default_get(fields)
		import datetime
		fecha_hoy = str(datetime.datetime.now())[:10]
		fecha_inicial = fecha_hoy[:4] + '-01-01' 
		res.update({'fecha_ini_mod':fecha_inicial})
		res.update({'fecha_fin_mod':fecha_hoy})
		res.update({'fecha_inicio':fecha_inicial})
		res.update({'fecha_final':fecha_hoy})

		locat_ids = self.env['stock.location'].search([('usage','in',('internal','inventory','transit','procurement','production'))])
		locat_ids = [s.id for s in locat_ids]
		res.update({'ubicaciones':[(6,0,locat_ids)]})
		res.update({'alllocations':True})
		return res

	@api.onchange('alllocations')
	def onchange_alllocations(self):
		if self.alllocations == True:
			locat_ids = self.env['stock.location'].search( [('usage','in',('internal','inventory','transit','procurement','production'))] )
			self.ubicaciones = [(6,0,locat_ids.ids)]
		else:
			self.ubicaciones = [(6,0,[])]







	@api.multi
	def update_or_create_table(self):
		s_prod = [-1,-1,-1]
		s_loca = [-1,-1,-1]
		productos='{0,'
		almacenes='{0,'
		
		lst_products  = self.env['product.product'].search([('product_tmpl_id','=',self.env.context['active_id'] )])

		for producto in lst_products:
			productos=productos+str(producto.id)+','
			s_prod.append(producto.id)
		productos=productos[:-1]+'}'

		lst_locations  = self.env['stock.location'].search([('usage','in',('internal','inventory','transit','procurement','production'))])

		for location in self.ubicaciones:
			almacenes=almacenes+str(location.id)+','
			s_loca.append(location.id)
		almacenes=almacenes[:-1]+'}'

		date_ini=self.fecha_inicio
		date_fin=self.fecha_final
		if False:

			
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

			worksheet.write(2,1,date_ini)
			worksheet.write(3,1,date_fin)			
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



			self.env.cr.execute(""" 
				 
				select 
origen.complete_name AS "Ubicación Origen", 
destino.complete_name AS "Ubicación Destino", 
almacen.complete_name AS "Almacén",
vstf.motivo_guia AS "Tipo de operación",
pc.name as "Categoria",
pt.name as "Producto",
pp.default_code as "Codigo P.",
pu.name as "unidad",
vstf.fecha as "Fecha",
sp.name as "Doc. Almacén",  
vstf.entrada as "Entrada",  
vstf.salida as "Salida"
from  
(
	select date::date as fecha,location_id as origen, location_dest_id as destino, location_dest_id as almacen, product_qty as entrada, 0 as salida,id  as stock_move,guia as motivo_guia,product_id from vst_stock_move_final
	union all
	select date::date as fecha,location_id as origen, location_dest_id as destino, location_id as almacen, 0 as entrada, product_qty as salida,id  as stock_move ,guia as motivo_guia ,product_id  from vst_stock_move_final
) as vstf
inner join stock_location origen on origen.id = vstf.origen
inner join stock_location destino on destino.id = vstf.destino
inner join stock_location almacen on almacen.id = vstf.almacen
inner join product_product pp on pp.id = vstf.product_id
inner join product_template pt on pt.id = pp.product_tmpl_id
inner join product_category pc on pc.id = pt.categ_id
inner join product_uom pu on pu.id = pt.uom_id
inner join stock_move sm on sm.id = vstf.stock_move
inner join stock_picking sp on sp.id = sm.picking_id
left join purchase_order po on po.id = sp.po_id
where vstf.fecha >='""" +str(date_ini)+ """' and vstf.fecha <='""" +str(date_fin)+ """'
and vstf.product_id in """ +str(tuple(s_prod))+ """
and vstf.almacen in """ +str(tuple(s_loca))+ """
and almacen.usage = 'internal'
order by 
origen.id,pp.id,sp.date,vstf.entrada desc 
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
				worksheet.write(x,5,line[5] if line[5] else '' ,bord )
				worksheet.write(x,6,line[6] if line[6] else '' ,bord )
				worksheet.write(x,7,line[7] if line[7] else '' ,bord )
				worksheet.write(x,8,line[8] if line[8] else '' ,bord )
				worksheet.write(x,9,line[9] if line[9] else '' ,bord )
				worksheet.write(x,10,line[10] if line[10] else 0 ,numberdos )				
				worksheet.write(x,11,line[11] if line[11] else 0 ,numberdos )
				
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



		if True:

			import io
			from xlsxwriter.workbook import Workbook
			output = io.BytesIO()
			########### PRIMERA HOJA DE LA DATA EN TABLA
			#workbook = Workbook(output, {'in_memory': True})

			direccion = self.env['main.parameter'].search([])[0].dir_create_file
			workbook = Workbook(direccion +'kardex_producto.xlsx')
			worksheet = workbook.add_worksheet("Kardex Producto")
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
			worksheet.write(4,0,'UNIDAD MEDIDA:',bold)
			worksheet.write(5,0,'PRODUCTO:',bold)
			worksheet.write(6,0,'CODIGO PRODUCTO:',bold)
			worksheet.write(7,0,'CUENTA CONTABLE:',bold)

			worksheet.write(2,1,self.fecha_inicio)
			worksheet.write(3,1,self.fecha_final)			
			worksheet.write(4,1,lst_products[0].uom_id.name if not lst_products[0].unidad_kardex.id else lst_products[0].unidad_kardex.name)
			worksheet.write(5,1,lst_products[0].name)
			worksheet.write(6,1,lst_products[0].default_code)
			worksheet.write(7,1,lst_products[0].categ_id.property_stock_valuation_account_id.code if lst_products[0].categ_id.property_stock_valuation_account_id.code else '' )
			import datetime		

			worksheet.merge_range(8,0,9,0, u"Fecha Alm.",boldbord)
			worksheet.merge_range(8,1,9,1, u"Fecha",boldbord)
			worksheet.merge_range(8,2,9,2, u"Tipo",boldbord)
			worksheet.merge_range(8,3,9,3, u"Serie",boldbord)
			worksheet.merge_range(8,4,9,4, u"Número",boldbord)
			worksheet.merge_range(8,5,9,5, u"T. OP.",boldbord)
			worksheet.merge_range(8,6,9,6, u"Proveedor",boldbord)
			worksheet.merge_range(8,7,8,8, "Ingreso",boldbord)
			worksheet.write(9,7, "Cantidad",boldbord)
			worksheet.write(9,8, "Costo",boldbord)
			worksheet.merge_range(8,9,8,10, "Salida",boldbord)
			worksheet.write(9,9, "Cantidad",boldbord)
			worksheet.write(9,10, "Costo",boldbord)
			worksheet.merge_range(8,11,8,12, "Saldo",boldbord)
			worksheet.write(9,11, "Cantidad",boldbord)
			worksheet.write(9,12, "Costo",boldbord)
			worksheet.merge_range(8,13,9,13, "Costo Adquisicion",boldbord)
			worksheet.merge_range(8,14,9,14, "Costo Promedio",boldbord)
			worksheet.merge_range(8,15,9,15, "Ubicacion Origen",boldbord)
			worksheet.merge_range(8,16,9,16, "Ubicacion Destino",boldbord)
			worksheet.merge_range(8,17,9,17, "Almacen",boldbord)
			worksheet.merge_range(8,18,9,18, "Cuenta Factura",boldbord)
			worksheet.merge_range(8,19,9,19, "Documento Almacen",boldbord)


			self.env.cr.execute(""" 
				 select 
				fecha as "Fecha",
				type_doc as "T. Doc.",
				serial as "Serie",
				nro as "Nro. Documento",
				operation_type as "Tipo de operacion",				 
				ingreso as "Ingreso Fisico",
				round(debit,6) as "Ingreso Valorado.",
				salida as "Salida Fisico",
				round(credit,6) as "Salida Valorada",
				saldof as "Saldo Fisico",
				round(saldov,6) as "Saldo valorado",
				round(cadquiere,6) as "Costo adquisicion",
				round(cprom,6) as "Costo promedio",
					origen as "Origen",
					destino as "Destino",
				almacen AS "Almacen",
				account_invoice as "Cuenta factura",
				stock_doc as "Doc. Almacén",
				fecha_albaran as "Fecha Alb.",
				name as "Proveedor"

				from get_kardex_v("""+ str(self.fecha_inicio).replace('-','') + "," + str(self.fecha_final).replace('-','') + ",'" + productos + """'::INT[], '""" + almacenes + """'::INT[]) 
			""")

			ingreso1= 0
			ingreso2= 0
			salida1= 0
			salida2= 0

			for line in self.env.cr.fetchall():
				worksheet.write(x,0,line[18] if line[18] else '' ,bord )
				worksheet.write(x,1,line[0] if line[0] else '' ,bord )
				worksheet.write(x,2,line[1] if line[1] else '' ,bord )
				worksheet.write(x,3,line[2] if line[2] else '' ,bord )
				worksheet.write(x,4,line[3] if line[3] else '' ,bord )
				worksheet.write(x,5,line[4] if line[4] else '' ,bord )
				
				worksheet.write(x,6,line[19] if line[19] else 0 ,numberdos )
				worksheet.write(x,7,line[5] if line[5] else 0 ,numberdos )
				worksheet.write(x,8,line[6] if line[6] else 0 ,numberdos )
				worksheet.write(x,9,line[7] if line[7] else 0 ,numberdos )
				worksheet.write(x,10,line[8] if line[8] else 0 ,numberdos )
				worksheet.write(x,11,line[9] if line[9] else 0 ,numberdos )
				worksheet.write(x,12,line[10] if line[10] else 0 ,numberdos )
				worksheet.write(x,13,line[11] if line[11] else 0 ,numberseis )
				worksheet.write(x,14,line[12] if line[12] else 0 ,numberocho )

				worksheet.write(x,15,line[13] if line[13] else '' ,bord )
				worksheet.write(x,16,line[14] if line[14] else '' ,bord )
				worksheet.write(x,17,line[15] if line[15] else '' ,bord )
				worksheet.write(x,18,line[16] if line[16] else '' ,bord )
				worksheet.write(x,19,line[17] if line[17] else '' ,bord )

				ingreso1 += line[5] if line[5] else 0
				ingreso2 +=line[6] if line[6] else 0
				salida1 +=line[7] if line[7] else 0
				salida2 += line[8] if line[8] else 0

				x = x +1

			tam_col = [11,11,5,5,7,5,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11]

			worksheet.write(x,5,'TOTALES:' ,bold )
			worksheet.write(x,6,ingreso1 ,numberdosbold )
			worksheet.write(x,7,ingreso2 ,numberdosbold )
			worksheet.write(x,8,salida1 ,numberdosbold )
			worksheet.write(x,9,salida2 ,numberdosbold )

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
			worksheet.set_column('T:T', tam_col[19])

			workbook.close()
			
			f = open(direccion + 'kardex_producto.xlsx', 'rb')
			
			
			sfs_obj = self.pool.get('repcontab_base.sunat_file_save')
			vals = {
				'output_name': 'ProductoKardex.xlsx',
				'output_file': base64.encodestring(''.join(f.readlines())),		
			}

			sfs_id = self.env['export.file.save'].create(vals)

			return {
			    "type": "ir.actions.act_window",
			    "res_model": "export.file.save",
			    "views": [[False, "form"]],
			    "res_id": sfs_id.id,
			    "target": "new",
			}
