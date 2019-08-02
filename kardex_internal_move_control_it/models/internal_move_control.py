# -*- coding: utf-8 -*-

from odoo import models, fields, api,exceptions

class main_parameter(models.Model):
	_inherit = 'main.parameter'

	usar_ruta = fields.Boolean(u'Trabajar con Mercaderia en Tránsito',default=False)

class picking_recepcion_ruta(models.Model):
	_name = 'picking.recepcion.ruta'

	date = fields.Date('Fecha Recepcion',required=True)

	@api.one
	def do_rebuild(self):
		picking =  self.env['stock.picking'].browse(self.env.context['active_id'])
		picking.usuario_recepcion = self.env.uid
		picking.fecha_recepcion_registro = fields.Date.today()
		picking.fecha_recepcion = self.date
		picking.en_ruta = False

		
		self.env.cr.execute("""
					select Todo.producto, Todo.almacen, Todo.saldo_fisico, coalesce(quants.cantidad,0), coalesce(quants_sinresernva.cantidad,0) from (
					select ubicacion as almacen, product_id as producto, pt.categ_id as categoria,
					sum(stock_disponible) as saldo,
					sum(saldo_fisico) as saldo_fisico,
					sum(por_ingresar) as por_ingresar,
					sum(transito) as transito,
					sum(salida_espera) as salida_espera,
					sum(reservas) as reservas,
					sum(previsto) as saldo_virtual,

					replace(replace(array_agg(id_stock_disponible)::text,'{','['),'}',']') as id_stock_disponible,
					replace(replace(array_agg(id_saldo_fisico)::text,'{','['),'}',']') as id_saldo_fisico,
					replace(replace(array_agg(id_por_ingresar)::text,'{','['),'}',']') as id_por_ingresar,
					replace(replace(array_agg(id_transito)::text,'{','['),'}',']') as id_transito,
					replace(replace(array_agg(id_salida_espera)::text,'{','['),'}',']') as id_salida_espera,
					replace(replace(array_agg(id_reservas)::text,'{','['),'}',']') as id_reservas,
					replace(replace(array_agg(id_previsto)::text,'{','['),'}',']') as id_previsto

					from vst_kardex_onlyfisico_total
					inner join product_template pt on pt.id = product_tmpl_id
					where vst_kardex_onlyfisico_total.date >= '2019-01-01'
					and vst_kardex_onlyfisico_total.date <= '2019-12-31'
							and pt.tracking != 'lot'
					group by ubicacion, product_id, pt.categ_id
					order by ubicacion,product_id, pt.categ_id
					) Todo
					left join  (
					select sum(qty) as cantidad,product_id, location_id from stock_quant  group by product_id, location_id
					) quants on quants.product_id = Todo.producto and quants.location_id = Todo.almacen
					left join  (
					select sum(qty) as cantidad,product_id, location_id from stock_quant where reservation_id is not null group by product_id, location_id
					) quants_sinresernva on quants_sinresernva.product_id = Todo.producto and quants_sinresernva.location_id = Todo.almacen
					where Todo.saldo_fisico != coalesce(quants.cantidad,0)
					 """)
		for i in self.env.cr.fetchall():
			mov = self.env['stock.quant'].search([('product_id','=',i[0]),('location_id','=',i[1]),('reservation_id','=',False)])
			flag = True
			for el in mov:
				if flag:
					flag = False
				else:
					self.env.cr.execute(" delete from stock_quant where id = " + str(el.id) )
			if len(mov)>0:
				mov[0].qty = i[2] - i[4]
			else:
				data= {
					'qty':i[2] - i[4],
					'location_id':i[1],
					'product_id':i[0],
				}
				newquant = self.env['stock.quant'].create(data)


class internal_move_control(models.Model):
	_inherit = 'stock.picking'
	_description = "Control para movimientos internos de inventario"


	visible_ruta = fields.Boolean('Visible Ruta',compute="get_visible_ruta")
	en_ruta = fields.Boolean(string='En Transito',default=True)
	usuario_recepcion = fields.Many2one('res.users','Persona Recepciono')
	fecha_recepcion = fields.Date('Fecha Recepción')
	fecha_recepcion_registro = fields.Date('Fecha de Registro')


	@api.one
	def get_visible_ruta(self):
		flag = False	
		param = self.env['main.parameter'].search([])[0]
		if self.location_id.usage == 'internal' and self.location_dest_id.usage =='internal' and param.usar_ruta:
			flag = True
		self.visible_ruta = flag


	@api.model
	def default_get(self,fields):
		res = super(internal_move_control,self).default_get(fields)
		param = self.env['main.parameter'].search([])[0]
		res['en_ruta']        = True if param.usar_ruta else False
		return res


	@api.multi
	def recepcionar_ruta(self):
		return {
			'type': 'ir.actions.act_window',
			'res_model': 'picking.recepcion.ruta',
			'view_mode': 'form',
			'view_type': 'form',
			'target': 'new',
		}

class movimientos_en_ruta(models.Model):
	_name = 'movimientos.en.ruta'

	@api.multi
	def get_en_ruta(self):
		return {
			'domain' : [('en_ruta','=',True),('location_id.usage','=','internal'),('location_dest_id.usage','=','internal')],
			'type': 'ir.actions.act_window',
			'name': 'Movimiento Transito',
			'res_model': 'stock.picking',
			'view_mode': 'tree,form',
			'view_type': 'form',
			'views': [(False, 'tree'),(False,'form')],
		}

class control_product_template(models.Model):
	_inherit = 'product.template'

	@api.one
	def get_saldofisico(self):
		self.env.cr.execute("""
					select * from (
					select pt.name,vst_kardex_onlyfisico_total.product_tmpl_id, sum(stock_disponible) as a, sum(previsto) as b from vst_kardex_onlyfisico_total
					inner join product_template pt on pt.id = vst_kardex_onlyfisico_total.product_tmpl_id
					where vst_kardex_onlyfisico_total.product_tmpl_id = """+str(self.id)+""" 
					group by pt.name,vst_kardex_onlyfisico_total.product_tmpl_id
					) Todo
					order by name, product_tmpl_id,a

		 """)
		tmp = 0
		tmp2 = 0
		for i in self.env.cr.fetchall():
			tmp += i[2]
			tmp2 += i[3]
		self.saldo_kardexfisico = tmp
		self.saldo_kardexfisico_previsto = tmp2

	saldo_kardexfisico = fields.Float('Disponibilidad',compute="get_saldofisico")

	saldo_kardexfisico_previsto = fields.Float('Previsto',compute="get_saldofisico")

	@api.multi
	def get_saldo_kardexfisico(self):
		detalle = self.env['detalle.simple.kfisico'].create({'name':self.name_get()[0][1]})

		self.env.cr.execute("""

					select * from (
					select ubicacion, product_id, sum(stock_disponible) as a,sum(saldo_fisico) as b,sum(por_ingresar) as c,sum(transito) as d,sum(salida_espera) as e,sum(reservas) as f, sum(previsto) as g 
					,array_agg(id_stock_disponible),array_agg(id_saldo_fisico),array_agg(id_por_ingresar),array_agg(id_transito)
					,array_agg(id_salida_espera),array_agg(id_reservas),array_agg(id_previsto)
					from vst_kardex_onlyfisico_total
					where product_tmpl_id = """+str(self.id)+""" 
					group by ubicacion, product_id
					) Todo
					order by ubicacion, product_id,a

		 """)
		txt = ""
		for i in self.env.cr.fetchall():
			self.env['detalle.simple.kfisico.d'].create({'almacen':i[0],'product_id':i[1],'saldo':i[2],'saldo_fisico':i[3],'por_ingresar':i[4],'transito':i[5],'salida_espera':i[6],'reservas':i[7],'saldo_virtual':i[8],'id_stock_disponible':str(i[9]),'id_saldo_fisico':str(i[10]),'id_por_ingresar':str(i[11]),'id_transito':str(i[12]),'id_salida_espera':str(i[13]),'id_reservas':str(i[14]),'id_previsto':str(i[15]),'padre':detalle.id})
	

		view_id = self.env.ref('kardex_product_saldofisico_it.view_detalle_simple_kfisico_form',False)
		return {
				'type': 'ir.actions.act_window',
				'res_model': 'detalle.simple.kfisico',
				'view_mode': 'form',
				'view_type': 'form',
				'target':'new',
				'res_id': detalle.id,
				'view_id': view_id.id,
				'views': [(view_id.id, 'form')],
			}

class control_product(models.Model):
	_inherit = 'product.product'
	@api.one
	def get_saldofisico(self):
		self.env.cr.execute("""

					select * from (
					select pt.name,vst_kardex_onlyfisico_total.product_id, sum(stock_disponible) as a, sum(previsto) as b from vst_kardex_onlyfisico_total
					inner join product_template pt on pt.id = vst_kardex_onlyfisico_total.product_tmpl_id
					where vst_kardex_onlyfisico_total.product_id = """+str(self.id)+""" 
					group by pt.name,vst_kardex_onlyfisico_total.product_id
					) Todo
					order by name, product_id,a

		 """)
		tmp = 0
		tmp2 = 0
		for i in self.env.cr.fetchall():
			tmp += i[2]
			tmp2 += i[3]
		self.saldo_kardexfisico = tmp
		self.saldo_kardexfisico_previsto = tmp2

	saldo_kardexfisico = fields.Float('Disponibilidad',compute="get_saldofisico")

	saldo_kardexfisico_previsto = fields.Float('Previsto',compute="get_saldofisico")

	@api.multi
	def get_saldo_kardexfisico(self):
		detalle = self.env['detalle.simple.kfisico'].create({'name':self.name_get()[0][1]})

		self.env.cr.execute("""

					select * from (
					select ubicacion, product_id, sum(stock_disponible) as a,sum(saldo_fisico) as b,sum(por_ingresar) as c,sum(transito) as d,sum(salida_espera) as e,sum(reservas) as f, sum(previsto) as g 
					,array_agg(id_stock_disponible),array_agg(id_saldo_fisico),array_agg(id_por_ingresar),array_agg(id_transito)
					,array_agg(id_salida_espera),array_agg(id_reservas),array_agg(id_previsto)
					from vst_kardex_onlyfisico_total
					where product_id = """+str(self.id)+""" 
					group by ubicacion, product_id
					) Todo
					order by ubicacion, product_id,a

		 """)
		txt = ""
		for i in self.env.cr.fetchall():
			self.env['detalle.simple.kfisico.d'].create({'almacen':i[0],'product_id':i[1],'saldo':i[2],'saldo_fisico':i[3],'por_ingresar':i[4],'transito':i[5],'salida_espera':i[6],'reservas':i[7],'saldo_virtual':i[8],'id_stock_disponible':str(i[9]),'id_saldo_fisico':str(i[10]),'id_por_ingresar':str(i[11]),'id_transito':str(i[12]),'id_salida_espera':str(i[13]),'id_reservas':str(i[14]),'id_previsto':str(i[15]),'padre':detalle.id})	

		view_id = self.env.ref('kardex_product_saldofisico_it.view_detalle_simple_kfisico_producto_form',False)

		return {
				'type': 'ir.actions.act_window',
				'res_model': 'detalle.simple.kfisico',
				'view_mode': 'form',
				'view_type': 'form',
				'target':'new',
				'res_id': detalle.id,
				'view_id': view_id.id,
				'views': [(view_id.id, 'form')],
			} 
