# -*- coding: utf-8 -*-
from odoo.tools.misc import DEFAULT_SERVER_DATETIME_FORMAT
from openerp.exceptions import Warning
import time
from odoo.exceptions import UserError
import odoo.addons.decimal_precision as dp
from openerp.osv import osv
import base64
from odoo import models, fields, api
from datetime import datetime, timedelta
import codecs
values = {}

import datetime

class sale_order_inherit(models.Model):
	_inherit = 'account.invoice'
	control_limite_factura_excedida = fields.Boolean('Control Facturas Excedidas',default=False)
	control_limite_factura_excedida_aceptada = fields.Boolean('Control Facturas Excedidas Aceptadas',default=False)


	@api.multi
	def account_invoice_open_2(self):
		for record in self:
			record.validacion_factura_excedida()
			if record.control_limite_factura_excedida == True:
				print('entro')
				view = self.env.ref('limitador_facturas_it.view_account_invoice_limit_confirmation')
				wiz = self.env['account.invoice.limit.confirmation'].create({'account_invoice_id': record.id})
				return {
					'name': '¿Validar Factura?',
					'type': 'ir.actions.act_window',
					'view_type': 'form',
					'view_mode': 'form',
					'res_model': 'account.invoice.limit.confirmation',
					'views': [(view.id, 'form')],
					'view_id': view.id,
					'target': 'new',
					'res_id': wiz.id,
					'context': self.env.context,
				}
			else:
				return record.action_invoice_open()

	@api.multi
	def validacion_factura_excedida(self):
		for order in self:
			order.control_limite_factura_excedida = False
			self.env.cr.execute("""
				select equipo_ventas_lim_fac,limite_facturas from main_parameter
			""")
			equipo = 0
			limite = 0
			control = self.env.cr.fetchall()
			if len(control)>0:
				for controles in control:
					equipo = controles[0]
					print(equipo)
					limite = controles[1]
					print(limite)
				if order.team_id.id == equipo:
					self.env.cr.execute("""
						select count(*)::Integer as conteo from account_invoice where partner_id = """+str(order.partner_id.id)+""" and state = 'open'
					""")
					control_2 = self.env.cr.fetchall()
					if len(control_2) > 0 :
						for controlando in control_2:
							conteo = controlando[0]
						if conteo>limite:
							order.control_limite_factura_excedida = True



class main_parameter_inherit(models.Model):
	_inherit = 'main.parameter'
	equipo_ventas_lim_fac = fields.Many2one('crm.team','Equipo de Ventas a Limitar')
	limite_facturas = fields.Integer('Limite de Facturas por Cliente(Equipo Ventas)')