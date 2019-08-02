# -*- coding: utf-8 -*-

from collections import namedtuple
import json
import time

from odoo import api, fields, models, _ , exceptions
from odoo.tools import DEFAULT_SERVER_DATETIME_FORMAT
from odoo.tools.float_utils import float_compare
from odoo.addons.procurement.models import procurement
from odoo.exceptions import UserError

class stock_location_path(models.Model):
	_inherit = "stock.location.path"

	def _prepare_move_copy_values(self,move_to_copy,new_date):
		t =  super(stock_location_path,self)._prepare_move_copy_values(move_to_copy,new_date)
		print "mmm a chido"
		print t
		return t

class PickingType(models.Model):
	_inherit = "stock.picking"


	einvoice_12 = fields.Many2one('einvoice.catalog.12', u'Tipo de Operacion SUNAT')

	fecha_kardex = fields.Date(string='Fecha kardex', readonly=False)

	invoice_id = fields.Many2one('account.invoice', 'Factura')

	state_invoice = fields.Char(u'Estado de factura', compute='calc_state_invoice')

	es_fecha_kardex = fields.Boolean('Usar Fecha kardex',default=True)

	po_id = fields.Many2one('stock.picking', 'Orden de pedido')

	marca = fields.Char('Marca', size=12)

	placa = fields.Char('Placa', size=12)

	nro_const = fields.Char('Numero de constancia de inscripcion', size=12)

	licencia = fields.Char('Licencia de Conducir N°(5)', size=12)

	nombre = fields.Char('Nombre')

	ruc = fields.Char('Ruc', size=100)

	tipo = fields.Char('Tipo', size=12)

	nro_comp = fields.Char('Numero de comprobante', size=12)

	nro_guia = fields.Char('Numero de guia', size=12)

	fecha_traslado = fields.Datetime(string='Fecha de traslado')

	punto_partida = fields.Char('Punto de partida', size=100)

	punto_llegada = fields.Char('Punto de llegada', size=100)

	@api.one
	def calc_state_invoice(self):
		if self.invoice_id:
			dic_state = {'draft': 'Borrador', 'proforma': 'Pro-forma', 'proforma2': 'Pro-forma', 'open': 'Abierto',
						 'paid': 'Pagado', 'cancel': 'Cancelado'}
			self.state_invoice = dic_state[self.invoice_id.state]
		else:
			self.state_invoice = ''

	@api.model
	def create(self,vals):
		t = super(PickingType,self).create(vals)
		if t.picking_type_id.warehouse_id.id and t.picking_type_id.warehouse_id.partner_id.id and t.picking_type_id.warehouse_id.partner_id.street:
			t.punto_partida = t.picking_type_id.warehouse_id.partner_id.street
		if t.partner_id.id and t.partner_id.street:
			t.punto_llegada = t.partner_id.street
		return t

	@api.one
	def write(self,vals):
		# if 'partner_id' in vals:
		# 	if vals['partner_id']:
		# 		p = self.env['res.partner'].browse(vals['partner_id'])
		# 		vals['punto_llegada'] = p.street if p.street else False
		# 	else:
		# 		vals['punto_llegada'] = False
		
		if 'picking_type_id' in vals:
			p = self.env['stock.picking.type'].browse(vals['picking_type_id'])
			if p.warehouse_id.id and p.warehouse_id.partner_id.id:
				vals['punto_partida'] = p.warehouse_id.partner_id.street if p.warehouse_id.partner_id.street else False

		t = super(PickingType,self).write(vals)
		return t


	@api.multi
	def _create_backorder(self, backorder_moves=[]):
		""" Move all non-done lines into a new backorder picking. If the key 'do_only_split' is given in the context, then move all lines not in context.get('split', []) instead of all non-done lines.
		"""
		# TDE note: o2o conversion, todo multi
		backorders = super(PickingType, self)._create_backorder(backorder_moves)
		for backorder in backorders:
			for i in backorder.pack_operation_product_ids:
				p_qty = i.product_qty
				i.write({'qty_done':p_qty})
		return backorders



class purchase_order(models.Model):
	_inherit = 'purchase.order'


	@api.model
	def _prepare_picking(self):
		#array_flag = {}
		#array_currency_original = {}
		#for order in self:
		#	array_flag[order.id] = False
		#	array_currency_original[order.id] = order.currency_id.id

		#	if order.currency_id.name == 'USD':
		#		array_flag[order.id] = True
		#		order.currency_id = self.env['res.currency'].search([('name','=','PEN')])[0].id


		t = super(purchase_order,self)._prepare_picking()
		from datetime import datetime, timedelta
		fecha = datetime(day=int(str(self.date_order)[:10].split('-')[2]),month=int(str(self.date_order)[:10].split('-')[1]),year=int(str(self.date_order)[:10].split('-')[0]),hour=  int(str(self.date_order).split(' ')[1].split(':')[0]), minute=int(str(self.date_order).split(' ')[1].split(':')[1]), second=int(str(self.date_order).split(' ')[1].split(':')[2])) - timedelta(hours=5)
		t['fecha_kardex']= str(fecha)[:10]
		t['einvoice_12'] = self.env['einvoice.catalog.12'].search([('code','=','02')])[0].id

		#for order in self:
		#	if array_flag[order.id]:
		#		order.currency_id = array_currency_original[order.id]
		return t


class purchase_order_line(models.Model):
	_inherit = 'purchase.order.line'

	@api.onchange('product_id')
	def onchange_product_id(self):
		self.account_analytic_id = self.product_id.analytic_account_id.id if self.product_id.id else False
		t = super(purchase_order_line,self).onchange_product_id()
		return t
    	

	@api.multi
	def _get_stock_move_price_unit(self):
		self.ensure_one()
		line = self[0]
		order = line.order_id
		price_unit = line.price_unit
		if line.taxes_id:
			price_unit = line.taxes_id.with_context(round=False).compute_all(
				price_unit, currency=line.order_id.currency_id, quantity=1.0, product=line.product_id, partner=line.order_id.partner_id
			)['total_excluded']
		if line.product_uom.id != line.product_id.uom_id.id:
			price_unit *= line.product_uom.factor / line.product_id.uom_id.factor
		return price_unit


class sale_order(models.Model):
	_inherit='sale.order'

	@api.multi
	def action_confirm(self):
		#array_flag = {}
		#array_currency_original = {}
		#for order in self:
		#	array_flag[order.id] = False
		#	array_currency_original[order.id] = order.pricelist_id.currency_id

		#	if order.pricelist_id.currency_id.name == 'USD':
		#		array_flag[order.id] = True
		#		order.pricelist_id.currency_id = self.env['res.currency'].search([('name','=','PEN')])[0].id


		t = super(sale_order,self).action_confirm()
		for order in self:
			picking_ids = self.env['stock.picking'].search([('group_id', '=', order.procurement_group_id.id)]) if order.procurement_group_id else []
			for i in picking_ids:
				from datetime import datetime, timedelta
				fecha = datetime(day=int(str(self.date_order)[:10].split('-')[2]),month=int(str(self.date_order)[:10].split('-')[1]),year=int(str(self.date_order)[:10].split('-')[0]),hour=  int(str(self.date_order).split(' ')[1].split(':')[0]), minute=int(str(self.date_order).split(' ')[1].split(':')[1]), second=int(str(self.date_order).split(' ')[1].split(':')[2])) - timedelta(hours=5)
				i.fecha_kardex = str(fecha)
				i.einvoice_12 = self.env['einvoice.catalog.12'].search([('code','=','01')])[0].id


		#for order in self:
		#	if array_flag[order.id]:
		#		order.pricelist_id.currency_id = array_currency_original[order.id]

		return t


class sale_order_line(models.Model):
	_inherit = 'sale.order.line'


	@api.onchange('product_id','product_uom_qty', 'product_uom', 'route_id')
	def _onchange_product_id_check_availability(self):
		return {}
		if not self.product_id or not self.product_uom_qty or not self.product_uom:
			self.product_packaging = False
			return {}
		if self.product_id.type == 'product':

			self.env.cr.execute("""
				select u,p,s ,sv
				from (
					select coalesce(X.ubicacion,""" +str(self.order_id.warehouse_id.pick_type_id.default_location_src_id.id)+ """) as u ,pp.id as p ,coalesce(saldo,0.000) as s , coalesce(saldo_virtual,0.000) as sv
					from product_product pp 
					left join (
						select product_id,ubicacion, sum(case when estado = 'done' then saldo else 0 end ) as saldo, sum(saldo) as saldo_virtual
						from (
							select v.product_id,v.location_id as ubicacion, -v.product_qty as saldo, estado			 
							from vst_kardex_fisico  v
							join stock_location sl on v.location_id = sl.id
							where date::date between '"""+self.order_id.date_order.split('-')[0]+"""-01-01'::date and '"""+str(int(self.order_id.date_order.split('-')[0])+10)+"""-01-01'::date and v.product_id = """ +str(self.product_id.id)+ """ and v.location_id = """ +str(self.order_id.warehouse_id.pick_type_id.default_location_src_id.id)+ """ and sl.usage = 'internal'
							union all
							select v.product_id,v.location_dest_id as ubicacion, v.product_qty as saldo, estado 
							from vst_kardex_fisico  v
							join stock_location sl on v.location_dest_id = sl.id
join stock_move sm on sm.id = v.id
join stock_picking sp on sm.picking_id = sp.id
join stock_location l_o on l_o.id = v.location_id
join stock_location l_d on l_d.id = v.location_dest_id
							where date::date between '"""+self.order_id.date_order.split('-')[0]+"""-01-01'::date and '"""+str(int(self.order_id.date_order.split('-')[0])+10)+"""-01-01'::date and v.product_id = """ +str(self.product_id.id)+ """ and v.location_dest_id = """ +str(self.order_id.warehouse_id.pick_type_id.default_location_src_id.id)+ """ and sl.usage = 'internal'
							and ( (l_o.usage = 'internal' and l_o.usage = 'internal' and coalesce(sp.en_ruta,false) = false )  or ( l_o.usage != 'internal' or l_o.usage != 'internal' )   )
						) as T group by product_id,ubicacion
					)as X on pp.id = X.product_id
					where pp.id = """ +str(self.product_id.id)+ """
					order by pp.id, saldo
				) as MN
				order by u
			 """)
			contenedor = self.env.cr.fetchall()




			print contenedor,'nlu'

			product_uom_deberia = self.product_id.unidad_kardex if self.product_id.unidad_kardex.id else self.product_id.uom_id
			product_uom_actual = self.product_uom

			total = ((self.product_uom_qty*product_uom_deberia.factor) / product_uom_actual.factor)
			
			print len(contenedor)>0, total ,contenedor[0][2]
			if len(contenedor)>0 and total > contenedor[0][2]:
				contenedor = contenedor[0]
				warning_mess = {
					'title': _('No dispone de inventario!'),
					'message' : _('Planea vender '+ str(total) + ' ' + product_uom_deberia.name +' pero solo dispone de ' + str(contenedor[2]) + ' '+ product_uom_deberia.name ) 
				}
				return {'warning': warning_mess}
			elif len(contenedor) ==0:
				if total > 0:
					warning_mess = {
						'title': _('No dispone de inventario!'),
						'message' : _('Planea vender '+ str(total) + ' ' + product_uom_deberia.name +' pero solo dispone de 0 ' + product_uom_deberia.name ) 
					}
					return {'warning': warning_mess}
		return {}


class gastos_vinculados_distribucion(models.Model):
	_name = 'gastos.vinculados.distribucion'

	name = fields.Char('Nombre')
	guia_remision = fields.Char('Guia de Remisión')
	fecha = fields.Date('Fecha')
	proveedor = fields.Many2one('res.partner','Proveedor')
	monto = fields.Float('Monto',digits=(12,2))
	detalle = fields.One2many('gastos.vinculados.distribucion.detalle','distribucion_id','Detalle')
	state = fields.Selection([('draft','Borrador'),('done','Finalizado')],'Estado',default="draft")
	picking = fields.Many2one('stock.picking','Albaran')


	def agregar_lineas(self):
		if self.picking.id:
			total = []
			for i in self.picking.move_lines:
				data={
						'move_id':i.id,
						'distribucion_id':self.id,
				}
				self.env['gastos.vinculados.distribucion.detalle'].create(data)


	@api.one
	def unlink(self):
		if self.state == 'done':
			raise exceptions.Warning( "No se puede eliminar un gastos vinculado Finalizado" )
		return super(gastos_vinculados_distribucion,self).unlink()


	@api.model
	def create(self,vals):
		t = super(gastos_vinculados_distribucion,self).create(vals)


		id_seq = self.env['ir.sequence'].search([('name','=','Gastos Vinculados')])
		if len(id_seq)>0:
			id_seq = id_seq[0]
		else:
			id_seq = self.env['ir.sequence'].create({'name':'Gastos Vinculados','implementation':'standard','active':True,'prefix':'GV-','padding':4,'number_increment':1,'number_next_actual' :1})
		t.write({'name': id_seq.next_by_id()})
		return t

	@api.one
	def prorratear(self):
		total = 0
		for i in self.detalle:
			if i.move_id.id:
				total += i.move_id.product_uom_qty

		rest = self.monto
		for i in range(len(self.detalle)):
			if i+1 == len(self.detalle):
				self.detalle[i].monto = rest
			else:
				self.detalle[i].monto = self.monto * (self.detalle[i].move_id.product_uom_qty /total)
				rest -= self.monto * (self.detalle[i].move_id.product_uom_qty /total)

	@api.one
	def finish(self):
		self.state = 'done'
		for i in self.detalle:
			i.move_id.linked_expense = i.monto

	@api.one
	def cancel(self):
		self.state = 'draft'


class gastos_vinculados_distribucion_detalle(models.Model):
	_name = 'gastos.vinculados.distribucion.detalle'

	move_id = fields.Many2one('stock.move','Linea Movimiento')
	monto = fields.Float('Monto',digits=(12,6))
	tipo = fields.Many2one('einvoice.catalog.01','Tipo Documento')
	nro_comprobante = fields.Char('Nro. Comprobante')
	distribucion_id = fields.Many2one('gastos.vinculados.distribucion','Cabecera')

	origen = fields.Many2one('stock.location',related='move_id.picking_id.location_id')
	destino = fields.Many2one('stock.location',related='move_id.picking_id.location_dest_id')
	cantidad=  fields.Float(related='move_id.product_uom_qty')
	unidad = fields.Many2one('product.uom',related='move_id.product_uom')
	albaran = fields.Many2one('stock.picking','Albaran',related='move_id.picking_id')
