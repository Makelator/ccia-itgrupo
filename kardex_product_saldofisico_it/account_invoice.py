# -*- coding: utf-8 -*-

from openerp import models, fields, api
from openerp.osv import osv
from odoo.tools.misc import formatLang

import datetime

class detalle_saldo_fisico(models.TransientModel):
	_name = 'detalle.saldo.fisico'

	move_id = fields.Many2one('stock.move','Movimiento')
	cantidad = fields.Float('Cantidad',related='move_id.product_uom_qty')
	unidad = fields.Many2one('product.uom',related='move_id.product_uom')
	fecha = fields.Date('Fecha Kardex', related='picking_id.fecha_kardex')
	picking_id = fields.Many2one('stock.picking','Albaran', related='move_id.picking_id')
	compra_id = fields.Many2one('purchase.order','Pedido de Compra',compute="get_compra_id")
	venta_id = fields.Many2one('sale.order','Pedido de Venta',compute="get_venta_id")

	_order = 'fecha'

	@api.one
	def get_compra_id(self):
		self.compra_id = self.move_id.purchase_line_id.order_id.id if self.move_id.purchase_line_id.id else False

	@api.one
	def get_venta_id(self):
		self.venta_id = self.picking_id.sale_id.id

class detalle_simple_fisico_total_d_wizard(models.TransientModel):
	_name = 'detalle.simple.fisico.total.d.wizard'

	fiscalyear_id = fields.Many2one('account.fiscalyear', u'Año fiscal', required=True)

	@api.model
	def default_get(self, fields):
		res = super(detalle_simple_fisico_total_d_wizard,self).default_get(fields)
		n = str(datetime.datetime.now().year)
		af = self.env['account.fiscalyear'].search([('name','=',n)])
		res['fiscalyear_id'] = af[0].id if len(af) else False
		return res

	@api.multi
	def do_rebuild(self):
		self.env.cr.execute("""
			drop view if exists detalle_simple_fisico_total_d;
			create view detalle_simple_fisico_total_d as (



					select row_number() OVER () AS id,* from (
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
					where vst_kardex_onlyfisico_total.date >= '"""+str(self.fiscalyear_id.name)+"""-01-01'
					and vst_kardex_onlyfisico_total.date <= '"""+str(self.fiscalyear_id.name)+"""-12-31'
					group by ubicacion, product_id, pt.categ_id
					order by ubicacion,product_id, pt.categ_id
					) Todo


			);
			""")

		view_id = self.env.ref('kardex_product_saldofisico_it.view_kardex_fisico_d',False)
		return {
			'type'     : 'ir.actions.act_window',
			'res_model': 'detalle.simple.fisico.total.d',
			# 'res_id'   : self.id,
			'view_id'  : view_id.id,
			'view_type': 'form',
			'view_mode': 'tree',
			'name': 'Saldos',
			'views'    : [(view_id.id, 'tree')],
			#'target'   : 'new',
			#'flags'    : {'form': {'action_buttons': True}},
			#'context'  : {},
		}

class detalle_simple_fisico_total_d(models.Model):
	_name = 'detalle.simple.fisico.total.d'

	producto = fields.Many2one('product.product','Producto')
	categoria = fields.Many2one('product.category',u'Categoría')
	almacen = fields.Many2one('stock.location','Almacen')
	saldo = fields.Float('Stock Disponible',digits=(15,3))
	saldo_fisico = fields.Float('Stock Fisico',digits=(15,3))
	por_ingresar = fields.Float('Por Ingresar',digits=(15,3))
	transito = fields.Float('Ingresos Transito',digits=(15,3))
	salida_espera = fields.Float('Salida Espera',digits=(15,3))
	reservas = fields.Float('Reservas',digits=(15,3))
	saldo_virtual = fields.Float('Previsto',digits=(15,3))

	id_stock_disponible = fields.Text('ids')
	id_saldo_fisico = fields.Text('ids')
	id_por_ingresar = fields.Text('ids')
	id_transito = fields.Text('ids')
	id_salida_espera = fields.Text('ids')
	id_reservas = fields.Text('ids')
	id_previsto = fields.Text('ids')



	@api.multi
	def get_stock_disponible(self):
		t = eval(self.id_stock_disponible.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}


	@api.multi
	def get_saldo_fisico(self):
		t = eval(self.id_saldo_fisico.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_por_ingresar(self):
		t = eval(self.id_por_ingresar.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_transito(self):
		t = eval(self.id_transito.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_salida_espera(self):
		t = eval(self.id_salida_espera.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_reservas(self):
		t = eval(self.id_reservas.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_saldo_virtual(self):
		t = eval(self.id_previsto.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}




	unidad = fields.Many2one('product.uom','Unidad',compute="get_unidad")




	@api.one
	def get_unidad(self):
		self.unidad = self.producto.unidad_kardex.id if self.producto.unidad_kardex.id else self.producto.uom_id.id

	_order = 'producto,categoria,almacen'
	_auto = False

class detalle_simple_kfisicot_d(models.Model):
	_name = 'detalle.simple.kfisicot.d'

	producto = fields.Many2one('product.product','Producto')
	unidad = fields.Many2one('product.uom','Unidad',compute="get_unidad")
	almacen = fields.Many2one('stock.location','Almacen')
	saldo = fields.Float('Stock Disponible',digits=(15,3))
	saldo_fisico = fields.Float('Stock Fisico',digits=(15,3))
	por_ingresar = fields.Float('Por Ingresar',digits=(15,3))
	transito = fields.Float('Ingresos Transito',digits=(15,3))
	salida_espera = fields.Float('Salida Espera',digits=(15,3))
	reservas = fields.Float('Reservas',digits=(15,3))
	saldo_virtual = fields.Float('Previsto',digits=(15,3))
	padre = fields.Many2one('detalle.simple.kfisicot','padre')

	id_stock_disponible = fields.Text('ids')
	id_saldo_fisico = fields.Text('ids')
	id_por_ingresar = fields.Text('ids')
	id_transito = fields.Text('ids')
	id_salida_espera = fields.Text('ids')
	id_reservas = fields.Text('ids')
	id_previsto = fields.Text('ids')



	@api.multi
	def get_stock_disponible(self):
		t = eval(self.id_stock_disponible.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}


	@api.multi
	def get_saldo_fisico(self):
		t = eval(self.id_saldo_fisico.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_por_ingresar(self):
		t = eval(self.id_por_ingresar.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_transito(self):
		t = eval(self.id_transito.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_salida_espera(self):
		t = eval(self.id_salida_espera.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_reservas(self):
		t = eval(self.id_reservas.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_saldo_virtual(self):
		t = eval(self.id_previsto.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}


	@api.one
	def get_unidad(self):
		self.unidad = self.producto.unidad_kardex.id if self.producto.unidad_kardex.id else self.producto.uom_id.id


class detalle_simple_kfisicot(models.Model):
	_name = 'detalle.simple.kfisicot'

	lineas=fields.One2many('detalle.simple.kfisicot.d','padre','Detalle')



class stock_picking(models.Model):
	_inherit = 'stock.picking'

	type_code_stock = fields.Char('Tipo Stock', compute='get_type_stock_picking_per')

	@api.multi
	def get_type_stock_picking_per(self):
		for i in self:
			i.type_code_stock = i.picking_type_id.code

	# select u,p,s from (
	# 		select sl.id as u ,pp.id as p ,saldo as s from (
	# 		select product_id,ubicacion, sum(saldo) as saldo from (
	# 		select product_id,location_id as ubicacion, -product_qty as saldo
	# 		from vst_stock_move_final_joya
	# 		where date::date between '"""+self.date.split('-')[0]+"""-01-01'::date and '"""+str(int(self.date.split('-')[0])+10)+"""-01-01'::date and product_id in """ +str(tuple(productos))+ """ and location_id = """ +str(locacion)+ """
	# 		union all
	# 		select product_id,location_dest_id as ubicacion, product_qty as saldo
	# 		from vst_stock_move_final_joya
	# 		where date::date between '"""+self.date.split('-')[0]+"""-01-01'::date and '"""+str(int(self.date.split('-')[0])+10)+"""-01-01'::date and product_id in """ +str(tuple(productos))+ """ and location_dest_id = """ +str(locacion)+ """
	# 		) as T group by product_id,ubicacion )as X
	# 		inner join stock_location sl on sl.id = X.ubicacion
	# 		inner join product_product pp on pp.id = X.product_id
	# 		where sl.usage = 'internal'
	# 		order by pp.name_template, saldo
	# 		) as MN
	# 		--where p in """ +str(tuple(productos))+ """
	# 		--and u = """ +str(locacion)+ """
	# 		order by u

	@api.multi
	def get_disponibilidad_kfisico(self):
		detalle = self.env['detalle.simple.kfisicot'].create({})
		productos=[-1,-1,-1]

		locacion = -1
		for i in self.move_lines:
			productos.append(i.product_id.id)
			locacion = i.location_id.id

		self.env.cr.execute("""



					select * from (
					select  product_id , ubicacion,
					sum(stock_disponible) as saldo,
					sum(saldo_fisico) as saldo_fisico,
					sum(por_ingresar) as por_ingresar,
					sum(transito) as transito,
					sum(salida_espera) as salida_espera,
					sum(reservas) as reservas,
					sum(previsto) as saldo_virtual
					,array_agg(id_stock_disponible),array_agg(id_saldo_fisico),array_agg(id_por_ingresar),array_agg(id_transito)
					,array_agg(id_salida_espera),array_agg(id_reservas),array_agg(id_previsto)


					from vst_kardex_onlyfisico_total
					where vst_kardex_onlyfisico_total.date >= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-01-01'
					and vst_kardex_onlyfisico_total.date <= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-12-31'
					and product_id in """ +str(tuple(productos))+ """
					group by ubicacion, product_id
					order by product_id,ubicacion
					) Todo
		 """)
		for i in self.env.cr.fetchall():
			self.env['detalle.simple.kfisicot.d'].create({'producto':i[0],'almacen':i[1],'saldo':i[2],'saldo_fisico':i[3],'por_ingresar':i[4],'transito':i[5],'salida_espera':i[6],'reservas':i[7],'saldo_virtual':i[8],'id_stock_disponible':str(i[9]),'id_saldo_fisico':str(i[10]),'id_por_ingresar':str(i[11]),'id_transito':str(i[12]),'id_salida_espera':str(i[13]),'id_reservas':str(i[14]),'id_previsto':str(i[15]),'padre':detalle.id})

		return {
				'type': 'ir.actions.act_window',
				'res_model': 'detalle.simple.kfisicot',
				'view_mode': 'form',
				'view_type': 'form',
				'target':'new',
				'name':'Saldos',
				'res_id': detalle.id,
				'views': [(False, 'form')],
			}









class detalle_simple_kfisico_d(models.Model):
	_name = 'detalle.simple.kfisico.d'

	almacen = fields.Many2one('stock.location','Almacen')
	saldo = fields.Float('Saldo disponible',digits=(15,3))

	saldo_fisico = fields.Float('Saldo Fisico',digits=(15,3))
	por_ingresar = fields.Float('Por Ingresar',digits=(15,3))
	transito = fields.Float('Transito',digits=(15,3))
	salida_espera = fields.Float('Salida Espera',digits=(15,3))
	reservas = fields.Float('Reservas',digits=(15,3))
	saldo_virtual = fields.Float('Previsto',digits=(15,3))
	product_id = fields.Many2one('product.product','Producto')
	padre = fields.Many2one('detalle.simple.kfisico','padre')

	id_stock_disponible = fields.Text('ids')
	id_saldo_fisico = fields.Text('ids')
	id_por_ingresar = fields.Text('ids')
	id_transito = fields.Text('ids')
	id_salida_espera = fields.Text('ids')
	id_reservas = fields.Text('ids')
	id_previsto = fields.Text('ids')



	@api.multi
	def get_stock_disponible(self):
		t = eval(self.id_stock_disponible.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}


	@api.multi
	def get_saldo_fisico(self):
		t = eval(self.id_saldo_fisico.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_por_ingresar(self):
		t = eval(self.id_por_ingresar.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_transito(self):
		t = eval(self.id_transito.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_salida_espera(self):
		t = eval(self.id_salida_espera.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_reservas(self):
		t = eval(self.id_reservas.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}

	@api.multi
	def get_saldo_virtual(self):
		t = eval(self.id_previsto.replace('None','0').replace('NULL','0'))
		elem = []
		for i in t:
			if i!= 0:
				data = {
					'move_id': i,
				}
				tmp = self.env['detalle.saldo.fisico'].create(data)
				elem.append(tmp.id)

		return {
			'domain' : [('id','in',elem)],
			'type': 'ir.actions.act_window',
			'res_model': 'detalle.saldo.fisico',
			'view_mode': 'tree',
			'view_type': 'form',
			'views': [(False, 'tree')],
			'target': 'new',
		}



class detalle_simple_kfisico(models.Model):
	_name = 'detalle.simple.kfisico'

	name = fields.Char('Producto')
	lineas=fields.One2many('detalle.simple.kfisico.d','padre','Detalle')



class product_template(models.Model):
	_inherit = 'product.template'

	@api.one
	def get_saldofisico(self):
		self.env.cr.execute("""



					select * from (
					select ubicacion,vst_kardex_onlyfisico_total.product_id, (stock_disponible) as a, (previsto) as b from vst_kardex_onlyfisico_total

					where vst_kardex_onlyfisico_total.date >= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-01-01'
					and vst_kardex_onlyfisico_total.date <= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-12-31'
					and vst_kardex_onlyfisico_total.product_tmpl_id = """+str(self.id)+"""
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
					select  product_id , ubicacion,
					sum(stock_disponible) as saldo,
					sum(saldo_fisico) as saldo_fisico,
					sum(por_ingresar) as por_ingresar,
					sum(transito) as transito,
					sum(salida_espera) as salida_espera,
					sum(reservas) as reservas,
					sum(previsto) as saldo_virtual
					,array_agg(id_stock_disponible),array_agg(id_saldo_fisico),array_agg(id_por_ingresar),array_agg(id_transito)
					,array_agg(id_salida_espera),array_agg(id_reservas),array_agg(id_previsto)

					from vst_kardex_onlyfisico_total
					where vst_kardex_onlyfisico_total.date >= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-01-01'
					and vst_kardex_onlyfisico_total.date <= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-12-31'
					and product_tmpl_id = """ +str(self.id)+ """
					group by ubicacion, product_id
					order by product_id,ubicacion
					) Todo

		 """)
		txt = ""
		for i in self.env.cr.fetchall():
			self.env['detalle.simple.kfisico.d'].create({'almacen':i[1],'product_id':i[0],'saldo':i[2],'saldo_fisico':i[3],'por_ingresar':i[4],'transito':i[5],'salida_espera':i[6],'reservas':i[7],'saldo_virtual':i[8],'id_stock_disponible':str(i[9]),'id_saldo_fisico':str(i[10]),'id_por_ingresar':str(i[11]),'id_transito':str(i[12]),'id_salida_espera':str(i[13]),'id_reservas':str(i[14]),'id_previsto':str(i[15]),'padre':detalle.id})


		view_id = self.env.ref('kardex_product_saldofisico_it.view_detalle_simple_kfisico_form',False)
		return {
				'type': 'ir.actions.act_window',
				'res_model': 'detalle.simple.kfisico',
				'view_mode': 'form',
				'view_type': 'form',
				'target':'new',
				'name':'Saldos',
				'res_id': detalle.id,
				'view_id': view_id.id,
				'views': [(view_id.id, 'form')],
			}



class product_product(models.Model):
	_inherit = 'product.product'

	@api.one
	def get_saldofisico(self):
		self.env.cr.execute("""



					select * from (
					select ubicacion,vst_kardex_onlyfisico_total.product_id, (stock_disponible) as a, (previsto) as b from vst_kardex_onlyfisico_total					
					where vst_kardex_onlyfisico_total.date >= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-01-01'
					and vst_kardex_onlyfisico_total.date <= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-12-31'
					and vst_kardex_onlyfisico_total.product_id = """+str(self.id)+"""
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
					select  product_id , ubicacion,
					sum(stock_disponible) as saldo,
					sum(saldo_fisico) as saldo_fisico,
					sum(por_ingresar) as por_ingresar,
					sum(transito) as transito,
					sum(salida_espera) as salida_espera,
					sum(reservas) as reservas,
					sum(previsto) as saldo_virtual
					,array_agg(id_stock_disponible),array_agg(id_saldo_fisico),array_agg(id_por_ingresar),array_agg(id_transito)
					,array_agg(id_salida_espera),array_agg(id_reservas),array_agg(id_previsto)

					from vst_kardex_onlyfisico_total
					where vst_kardex_onlyfisico_total.date >= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-01-01'
					and vst_kardex_onlyfisico_total.date <= '"""+str(self.env['main.parameter'].search([])[0].fiscalyear)+"""-12-31'
					and product_id = """ +str(self.id)+ """
					group by ubicacion, product_id
					order by product_id,ubicacion
					) Todo

		 """)
		txt = ""
		for i in self.env.cr.fetchall():
			self.env['detalle.simple.kfisico.d'].create({'almacen':i[1],'product_id':i[0],'saldo':i[2],'saldo_fisico':i[3],'por_ingresar':i[4],'transito':i[5],'salida_espera':i[6],'reservas':i[7],'saldo_virtual':i[8],'id_stock_disponible':str(i[9]),'id_saldo_fisico':str(i[10]),'id_por_ingresar':str(i[11]),'id_transito':str(i[12]),'id_salida_espera':str(i[13]),'id_reservas':str(i[14]),'id_previsto':str(i[15]),'padre':detalle.id})


		view_id = self.env.ref('kardex_product_saldofisico_it.view_detalle_simple_kfisico_producto_form',False)

		return {
				'type': 'ir.actions.act_window',
				'res_model': 'detalle.simple.kfisico',
				'view_mode': 'form',
				'view_type': 'form',
				'target':'new',
				'name':'Saldos',
				'res_id': detalle.id,
				'view_id': view_id.id,
				'views': [(view_id.id, 'form')],
			}

class purchase_order(models.Model):
	_inherit = 'purchase.order'

	@api.multi
	@api.depends('name', 'partner_ref')
	def name_get(self):
	    result = []
	    for po in self:
	        name = po.name
	        if po.partner_ref:
	            name += ' ('+po.partner_ref+')'
	        if 'nombre_reducido' not in self.env.context and po.amount_total:
	            name += ': ' + formatLang(self.env, po.amount_total, currency_obj=po.currency_id)
	        result.append((po.id, name))
	    return result
