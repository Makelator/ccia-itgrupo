# -*- encoding: utf-8 -*-
from openerp.osv import osv
import base64
from openerp import models, fields, api, exceptions, _
from odoo.exceptions import UserError


class gastos_vinculados_line(models.Model):
	_name = 'gastos.vinculados.line'
	stock_move_id = fields.Many2one('stock.move', 'Stock Move')

	# related
	picking_rel = fields.Many2one(
		'stock.picking', related='stock_move_id.picking_id')
	origen_rel = fields.Many2one(
		'stock.location', related='stock_move_id.location_id')
	destino_rel = fields.Many2one(
		'stock.location', related='stock_move_id.location_dest_id')
	producto_rel = fields.Many2one(
		'product.product', related='stock_move_id.product_id')
	unidad_rel = fields.Many2one(
		'product.uom', related='stock_move_id.product_uom')
	cantidad_rel = fields.Float(
		'Cantidad', related='stock_move_id.product_qty')
	precio_unitario_rel = fields.Float(
		'Precio Unitario', related='stock_move_id.price_unit')
	valor_rel = fields.Float('Valor', compute="get_valor_rel")

	factor = fields.Float('Factor', digits=(12, 6))
	flete = fields.Float('Flete', digits=(12, 6))
	gastos_id = fields.Many2one('gastos.vinculados.it', 'Gastos Vinculado')

	@api.one
	def get_valor_rel(self):
		self.valor_rel = self.cantidad_rel * self.precio_unitario_rel


class gastos_vinculados_it(models.Model):
	_name = 'gastos.vinculados.it'

	name = fields.Char('Nombre')

	partner_id = fields.Many2one('res.partner', 'Proveedor', required=True)

	# se filtrara basandose en este partner
	partner_almacen_id = fields.Many2one(
		'res.partner', 'Proveedor de existencias')

	invoice_id = fields.Many2one('account.invoice', 'Factura', required=False)
	purchase_order_id = fields.Many2one(
		'purchase.order', 'Pedido de Compra', required=False)

	date_invoice = fields.Date(
		'Fecha Factura GV', related='invoice_id.date_invoice')
	date_purchase = fields.Datetime(
		'Fecha Pedido', related='purchase_order_id.date_order')

	amount_invoice = fields.Monetary('Valor', digits=(
		12, 2), related='invoice_id.amount_untaxed')
	amount_purchase = fields.Monetary(
		'Valor', digits=(12, 2),  related='purchase_order_id.amount_untaxed')

	currency_id = fields.Many2one('res.currency', 'Currency', required=True,
								  default=lambda self: self.env.user.company_id.currency_id.id)

	tomar_valor = fields.Selection([('factura', 'Valor de Factura'), (
		'pedido', 'Valor de Pedido')], 'Tomar Valor en funcion', required=True)
	prorratear_en = fields.Selection(
		[('cantidad', 'Por Cantidad'), ('valor', 'Por Valor')], 'Prorratear en funcion', required=True)

	picking_ids = fields.Many2many(
		'stock.picking', 'gastos_vinculado_picking_rel', 'gastos_id', 'picking_id', 'Albaranes')
	detalle_ids = fields.One2many(
		'gastos.vinculados.line', 'gastos_id', 'Detalle')

	state = fields.Selection(
		[('draft', 'Borrador'), ('done', 'Terminado')], 'Estado', default='draft')

	total_flete = fields.Float(
		string='Total Flete', digits=(12, 2), store=True)
	total_cantidad = fields.Float(
		string='Total Cantidad', digits=(12, 2), store=True)
	total_valor = fields.Float(
		string='Total Valor', digits=(12, 2), store=True)
	total_factor = fields.Float(
		string='Total Factor', digits=(12, 2), store=True)
	tipo_moneda_cambio = fields.Float(string="Tipo de cambio", digits=(1, 3))


	@api.constrains('invoice_id','purchase_order_id','picking_ids')
	def _check_different_journal(self):
		# Check that the journal on these lines are different/same in the case
		# of cross journals/single journal
		if self.id:
			if self.invoice_id.id:
				existe = self.env['gastos.vinculados.it'].search([('invoice_id','=',self.invoice_id.id),('id','!=',self.id)])
				if len(existe)>0:
					rpta = ""
					for i in existe:
						rpta+= "Gastos Vinculado: " + i.name + " contiene la factura.\n"

			if self.purchase_order_id.id:
				existe = self.env['gastos.vinculados.it'].search([('purchase_order_id','=',self.purchase_order_id.id),('id','!=',self.id)])
				if len(existe)>0:
					rpta = ""
					for i in existe:
						rpta+= "Pedido de Compra: " + i.name + " contiene la factura.\n"



	@api.one
	def write(self,vals):
		t = super(gastos_vinculados_it,self).write(vals)
		self.refresh()
		if self.tomar_valor == 'factura':
			otros = self.env['gastos.vinculados.it'].search([('tomar_valor','=','factura'),('invoice_id','=',self.invoice_id.id),('state','=','done'),('id','!=',self.id)])
			if len(otros)>0:
				raise osv.except_osv(_('Error!'), _(
				'No puede utilizar una factura con un gasto vinculado enlazado anteriormente.'))

		if self.tomar_valor == 'pedido':
			otros = self.env['gastos.vinculados.it'].search([('tomar_valor','=','pedido'),('purchase_order_id','=',self.purchase_order_id.id),('state','=','done'),('id','!=',self.id)])
			if len(otros)>0:
				raise osv.except_osv(_('Error!'), _(
				'No puede utilizar un pedido de compra con un gasto vinculado enlazado anteriormente.'))
		return t

	@api.multi
	def verify_fields(self):
		if not self.invoice_id.id and not self.purchase_order_id.id:
			raise osv.except_osv(_('Error!'), _(
				'Se necesita al menos  el pedido de compras o la factura '))

		if self.tomar_valor == 'pedido':
			if not self.amount_purchase > 0:
				raise osv.except_osv(_('Error!'), _(
					'El "Valor de pedido" no puede ser 0'))
		else:
			if not self.amount_invoice > 0:
				raise osv.except_osv(_('Error!'), _(
					'El "Valor de factura" no puede ser 0'))

	@api.model
	def create(self, vals):
		if vals.get('invoice_id') == False and vals.get('purchase_order_id') == False:
			raise UserError(
				'Se necesita al menos  el pedido de compras o la factura ')

		t = super(gastos_vinculados_it, self).create(vals)
		id_seq = self.env['ir.sequence'].search(
			[('name', '=', 'gastos_vinculados_it')])
		if len(id_seq) > 0:
			id_seq = id_seq[0]
		else:
			id_seq = self.env['ir.sequence'].create({'name': 'gastos_vinculados_it', 'implementation': 'standard',
													 'active': True, 'prefix': 'GV-', 'padding': 4, 'number_increment': 1, 'number_next_actual': 1})
		t.write({'name': id_seq.next_by_id()})
		return t

	@api.one
	def unlink(self):
		if self.state == 'done':
			raise UserError(
				'No se puede eliminar un Gasto Vinculado Terminado')

		for i in self.picking_ids:
			i.unlink()

		for i in self.detalle_ids:
			i.unlink()

		t = super(gastos_vinculados_it, self).unlink()
		return t

	@api.one
	def procesar(self):
		# primero segun picking actualizamos los move
		#self.agregar_lineas()
		#self.calcular()
		self.state = 'done'

	@api.one
	def calcular(self):
		self.verify_fields()
		# actualizar el prorrateo
		self.refresh()
		self.total_flete = 0
		self.total_factor = 0
		self.tipo_moneda_cambio = 0
		total_valor = 0
		for i in self.detalle_ids:
			i.refresh()
			if self.tomar_valor == 'factura':
				total_valor = self.amount_invoice
				if self.invoice_id.currency_id.name == 'USD':
					factor_cambio = self.env['res.currency.rate'].search(
						[('currency_id', '=', self.invoice_id.currency_id.id), ('name', '=', self.invoice_id.date_invoice[:10])])
					if not factor_cambio:
						raise UserError(
							'No hay tipo de cambio para la fecha: %s' % self.invoice_id.date_invoice[:10])
					self.tipo_moneda_cambio = factor_cambio.type_sale
					total_valor = total_valor * factor_cambio.type_sale
			else:
				total_valor = self.amount_purchase
				if self.purchase_order_id.currency_id.name == 'USD':
					factor_cambio = self.env['res.currency.rate'].search(
						[('currency_id', '=', self.purchase_order_id.currency_id.id), ('name', '=', self.purchase_order_id.date_order[:10])])
					if not factor_cambio:
						raise UserError('No hay tipo de cambio para la fecha: %s' %
										self.purchase_order_id.date_order[:10])

					self.tipo_moneda_cambio = factor_cambio.type_sale
					total_valor = total_valor * factor_cambio.type_sale

			#total_valor = self.amount_invoice if self.tomar_valor == 'factura' else self.amount_purchase
			total_prorrateo = 0

			for m in self.detalle_ids:
				total_prorrateo += m.cantidad_rel if self.prorratear_en == 'cantidad' else m.valor_rel

			i.factor = ((i.cantidad_rel if self.prorratear_en == 'cantidad' else i.valor_rel) /
						total_prorrateo) if total_prorrateo != 0 else 0
			i.refresh()
			i.flete = i.factor * total_valor
			self.total_flete += i.flete
			self.total_factor += i.factor

		self.total_flete = self.total_flete + (total_valor - self.total_flete)
		self.total_factor = self.total_factor + (1 - self.total_factor)

	@api.one
	def agregar_lineas(self):
		# primero segun picking actualizamos los move
		# self.calculando()
		for i in self.detalle_ids:
			i.unlink()

		for i in self.picking_ids:
			for j in i.move_lines:  # i.move_ids:
				data = {
					'stock_move_id': j.id,
					'gastos_id': self.id,
				}
				self.env['gastos.vinculados.line'].create(data)

	@api.one
	def borrador(self):
		self.state = 'draft'


class StockPicking(models.Model):

	_inherit = 'stock.picking'
	bool_almacen_partner = fields.Boolean(
		"bool partner", compute='get_bool_almacen_partner')

	@api.one
	def get_bool_almacen_partner(self):
		if 'partner_almacen_id' in self.env.context and self.env.context['partner_almacen_id'] != False:
			self.bool_almacen_partner = True
		else:
			self.bool_almacen_partner = False
