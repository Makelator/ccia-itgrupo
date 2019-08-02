# -*- coding: utf-8 -*-

from collections import namedtuple
import json
import time

from odoo import api, fields, models, _
from odoo.tools import DEFAULT_SERVER_DATETIME_FORMAT
from odoo.tools.float_utils import float_compare
from odoo.addons.procurement.models import procurement
from odoo.exceptions import UserError


class InvoiceLine(models.Model):
	_inherit = "account.invoice.line"


	location_id = fields.Many2one('stock.location', 'Almacen')




class SaleAdvancePaymentInv(models.TransientModel):
	_inherit = "sale.advance.payment.inv"


	@api.one
	@api.depends('procurement_group_id_compute','albaranes')
	def get_procurement_group(self):
		order = self.env['sale.order'].browse(self._context.get('active_ids',[False])[0])
		if order.id:
			self.procurement_group_id_compute = order.procurement_group_id.id

	@api.multi
	def create_invoices(self):
		sale_orders = self.env['sale.order'].browse(self._context.get('active_ids',[]))
		if len(sale_orders)>0:
			facturas = sale_orders[0].invoice_ids.ids
			print "entro hoho"
			tt = super(SaleAdvancePaymentInv,self).create_invoices()
		legal = False
		if len(sale_orders)>0:
			ff  = sale_orders[0]
			ff.refresh()
			for i in ff.invoice_ids:
				if i.id not in facturas:
					legal = i.id
			for i in self.albaranes:
				i.invoice_id = legal
			return tt


	@api.depends('procurement_group_id_compute_ids','albaranes')
	@api.onchange('albaranes','procurement_group_id_compute')
	def onchange_albaranes_compute(self):
		orders = self.env['sale.order'].browse(self._context.get('active_ids',[False]))
		cont = [-1,-1,-1]
		for i in orders:
			if i.procurement_group_id.id:
				if i.procurement_group_id.id not in cont:
					cont.append(i.procurement_group_id.id)	
			# for line in i.order_line:
				# if line.procurement_group_id.id:
					# if line.procurement_group_id.id not in cont:
						# cont.append(line.procurement_group_id.id)
		res = {'domain':{'albaranes': [('group_id','in',cont),('state','=','done'),('invoice_id','=',False)] } }
		return res


	albaranes = fields.Many2many('stock.picking','stock_picking_sale_payment_inv','picking_id','sale_advance','Albaranes')
	procurement_group_id_compute = fields.Many2one('procurement.group',"Order ID",compute="get_procurement_group")



class AccountInvoice(models.Model):
	_inherit = "account.invoice"



	@api.onchange('payment_term_id', 'date_invoice')
	def _onchange_payment_term_date_invoice(self):
		date_invoice = self.date_invoice
		if not date_invoice:
			date_invoice = fields.Date.context_today(self)
		elif not self.payment_term_id.id:
			self.fecha_perception = date_invoice
			if self.partner_id.id:
				if self.type == 'out_invoice':
					if self.partner_id.property_payment_term_id.id:
						self.payment_term_id = self.partner_id.property_payment_term_id.id
					else:
						self.payment_term_id = 1
				if  self.type == 'in_invoice':
					if self.partner_id.property_supplier_payment_term_id.id:
						self.payment_term_id = self.partner_id.property_supplier_payment_term_id.id
					else:
						self.payment_term_id = 1
					# pay_days = 0
					# if self.partner_id.property_supplier_payment_term_id.id ==2:
					#	 pay_days = 15
					#	 pass
					# elif self.partner_id.property_supplier_payment_term_id.id ==3:
					#	 pay_days = 30
					#	 pass
					# from datetime import date, timedelta, datetime
					# dat_t = datetime.strptime(date_invoice, '%Y-%m-%d')
					# date_pay = dat_t+timedelta(days=pay_days)
					# date_pay_str=date_pay.strftime('%Y-%m-%d')
					# #import pdb; pdb.set_trace()
					# self.date_due = date_pay_str

		if not self.payment_term_id:
			# When no payment term defined
			self.date_due = self.date_due or self.date_invoice
		else:
			pterm = self.payment_term_id
			pterm_list = pterm.with_context(currency_id=self.company_id.currency_id.id).compute(value=1, date_ref=date_invoice)[0]
			self.date_due = max(line[0] for line in pterm_list)


