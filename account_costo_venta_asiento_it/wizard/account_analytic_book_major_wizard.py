# -*- encoding: utf-8 -*-
from openerp.osv import osv
import base64
from openerp import models, fields, api
import codecs
from datetime import *
from odoo.exceptions import UserError, ValidationError

class main_parameter(models.Model):
	_inherit = 'main.parameter'

	location_clientes = fields.Many2many('stock.location','location_parameter_rel','parameter_id','location_id','Ubicaciones de Clientes')

class view_costo_venta_wizard(osv.TransientModel):
	_name='view.costo.venta.wizard'

	period_id = fields.Many2one('account.period','Periodo',required=True)

	@api.multi
	def ver_informe(self):
		param = self.env['main.parameter'].search([])[0]
		ubicacion = [0,0,0,0,0,0]
		for i in param.location_clientes:
			ubicacion.append(i.id)
		self.env.cr.execute("""
			CREATE OR REPLACE view view_costo_venta_it as (

		select row_number() OVER () AS id,almacen_id as almacen,product_id as producto,sum(credit) as salidas,sum(debit) as devoluciones,sum(credit-debit) as costo_ventas, """ +str(self.period_id.id)+ """ as period_id from (	
select periodo,fecha,almacen,debit,credit,product_id,t1.location_id as almacen_id,ubicacion_origen,ubicacion_destino from (	
-- aca se selecciona hasta que periodo se ejecuta el kardex ,  con los resultados se filtra solo el mes cuyo costo de ventas queremos calcular	
select * from get_kardex_v(""" +str(param.fiscalyear)+ """0101,""" +str(param.fiscalyear)+ """0131, (select array_agg(id) from product_product), (select array_agg(id) from stock_location ) ))t1	
left join stock_location t2 on t2.id=t1.location_id	
where 	
-- colocar aca la ubicacion de clientes que esta configurada en parametros de contabilidad pestan kardex tanto para origen como para el destino	
(ubicacion_destino in """+str(tuple(ubicacion))+""" or ubicacion_origen in """+str(tuple(ubicacion))+""" ) and t2.usage='internal'	
--  colocar aca el periodo para el cual se quiere sacar el costo de ventas	
and periodo='""" +self.period_id.code+ """'	
)ab	
group by almacen_id,product_id	

)
	""")

		return {
				'type': 'ir.actions.act_window',
				'res_model': 'view.costo.venta.it',
				'view_mode': 'tree',
				'view_type': 'form',
				'views': [(False, 'tree')],
			}
		

	@api.multi
	def crear_asiento(self):

		param = self.env['main.parameter'].search([])[0]
		ubicacion = [0,0,0,0,0,0]
		for i in param.location_clientes:
			ubicacion.append(i.id)
		self.env.cr.execute("""
			CREATE OR REPLACE view view_costo_venta_it as (

		select row_number() OVER () AS id,almacen_id as almacen,product_id as producto,sum(credit) as salidas,sum(debit) as devoluciones,sum(credit-debit) as costo_ventas, """ +str(self.period_id.id)+ """ as period_id from (	

select periodo,fecha,almacen,debit,credit,product_id,t1.location_id as almacen_id,ubicacion_origen,ubicacion_destino from (	
-- aca se selecciona hasta que periodo se ejecuta el kardex ,  con los resultados se filtra solo el mes cuyo costo de ventas queremos calcular	
select * from get_kardex_v(""" +str(param.fiscalyear)+ """0101,""" +str(param.fiscalyear)+ """0131, (select array_agg(id) from product_product), (select array_agg(id) from stock_location ) ))t1	
left join stock_location t2 on t2.id=t1.location_id	
where 	
-- colocar aca la ubicacion de clientes que esta configurada en parametros de contabilidad pestan kardex tanto para origen como para el destino	
(ubicacion_destino in """+str(tuple(ubicacion))+""" or ubicacion_origen in """+str(tuple(ubicacion))+""" ) and t2.usage='internal'	
--  colocar aca el periodo para el cual se quiere sacar el costo de ventas	
and periodo='""" +self.period_id.code+ """'	
)ab	
group by almacen_id,product_id	

)
	""")

		param = self.env['main.parameter'].search([])[0]
		cabezado = {
			'journal_id':param.diario_destino.id,
			'date':self.period_id.date_stop,
			'ref':'COSTO VENTAS '+ self.period_id.code,
			'fecha_contable':self.period_id.date_stop,
			'ple_diariomayor':'1',
		}
		asiento = self.env['account.move'].create(cabezado)

		detalle = self.env['view.costo.venta.it'].search([])

		if len(detalle) == 0:
			raise UserError('No hay detalle para generar el asiento.')

		for i in detalle:
			if not i.cuenta_salida.id:
				raise UserError('No esta definido la cuenta de salida para el producto: ' + i.producto.name + '.')
			linea_obj = self.env['account.move.line'].search([('account_id','=',i.cuenta_salida.id),('move_id','=',asiento.id)])
			if len(linea_obj)== 0:
				linea = {
					'name':'COSTO VENTAS '+self.period_id.code,
					'account_id':i.cuenta_salida.id,
					'debit':abs(i.costo_ventas),
					'credit':0,
					'move_id':asiento.id,
				}
				self.env['account.move.line'].create(linea)
			else:
				linea_obj[0].debit +=abs(i.costo_ventas)



			if not i.cuenta_valuacion.id:
				raise UserError('No esta definido la cuenta de valuacion para el producto: ' + i.producto.name + '.')

			linea_obj = self.env['account.move.line'].search([('account_id','=',i.cuenta_valuacion.id),('move_id','=',asiento.id)])			
			if len(linea_obj)== 0:
				linea = {
					'name':'COSTO VENTAS '+self.period_id.code,
					'account_id':i.cuenta_valuacion.id,
					'debit':0,
					'credit':abs(i.costo_ventas),
					'move_id':asiento.id,
				}
				self.env['account.move.line'].create(linea)
			else:
				linea_obj[0].credit +=abs(i.costo_ventas)


		return {
				'type': 'ir.actions.act_window',
				'res_model': 'account.move',
				'view_mode': 'form',
				'view_type': 'form',
				'views': [(False, 'form')],
				'res_id':asiento.id,
			}		


	@api.multi
	def crear_asiento_parcial(self):
		lineas = self.env['view.costo.venta.wizard'].browse(self.env.context['active_ids'])

		param = self.env['main.parameter'].search([])[0]
		ubicacion = [0,0,0,0,0,0]
		for i in param.location_clientes:
			ubicacion.append(i.id)
		
		param = self.env['main.parameter'].search([])[0]
		cabezado = {
			'journal_id':param.diario_destino.id,
			'date':lineas[0].period_id.date_stop,
			'ref':'COSTO VENTAS '+ lineas[0].period_id.code,
			'fecha_contable':lineas[0].period_id.date_stop,
			'ple_diariomayor':'1',
		}
		asiento = self.env['account.move'].create(cabezado)

		detalle = lineas

		if len(detalle) == 0:
			raise UserError('No hay detalle para generar el asiento.')

		for i in detalle:
			if not i.cuenta_salida.id:
				raise UserError('No esta definido la cuenta de salida para el producto: ' + i.producto.name + '.')
			linea_obj = self.env['account.move.line'].search([('account_id','=',i.cuenta_salida.id),('move_id','=',asiento.id)])
			if len(linea_obj)== 0:
				linea = {
					'name':'COSTO VENTAS '+lineas[0].period_id.code,
					'account_id':i.cuenta_salida.id,
					'debit':abs(i.costo_ventas),
					'credit':0,
					'move_id':asiento.id,
				}
				self.env['account.move.line'].create(linea)
			else:
				linea_obj[0].debit +=i.costo_ventas



			if not i.cuenta_valuacion.id:
				raise UserError('No esta definido la cuenta de valuacion para el producto: ' + i.producto.name + '.')

			linea_obj = self.env['account.move.line'].search([('account_id','=',i.cuenta_salida.id),('move_id','=',asiento.id)])			
			if len(linea_obj)== 0:
				linea = {
					'name':'COSTO VENTAS '+lineas[0].period_id.code,
					'account_id':i.cuenta_valuacion.id,
					'debit':0,
					'credit':abs(i.costo_ventas),
					'move_id':asiento.id,
				}
				self.env['account.move.line'].create(linea)
			else:
				linea_obj[0].credit +=i.costo_ventas


		return {
				'type': 'ir.actions.act_window',
				'res_model': 'account.move',
				'view_mode': 'form',
				'view_type': 'form',
				'views': [(False, 'form')],
				'res_id':asiento.id,
			}		