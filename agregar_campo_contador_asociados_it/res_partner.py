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

class ResPartner(models.Model):
	_inherit = 'res.partner'

	asociados_count = fields.Integer(string='Delivery Orders', compute='_compute_asociados_ids')


	#conteo de cotizaciones
	@api.multi
	@api.depends('partner_ids_afiliados')
	def _compute_asociados_ids(self):
		for order in self:
			order.asociados_count = len(order.partner_ids_afiliados)

	@api.multi
	def action_view_asociados(self):
		'''
		esta funcion abre un tree si es que hay mas de un elemento
		y si solo hay uno abre el form con el elemento vinculado
		'''
		action = self.env.ref('socios_ccis_it.partner_afiliado_action').read()[0]

		pickings = self.mapped('partner_ids_afiliados')
		if len(pickings) > 1:
			action['domain'] = [('id', 'in', pickings.ids)]
		elif pickings:
			action['views'] = [(self.env.ref('socios_ccis_it.partner_afiliado_view').id, 'form')]
			action['res_id'] = pickings.id
		return action

	#conteo de cotizaciones
	@api.onchange('estado_afiliacion')
	def _onchange_change_afiliacion(self):
		print("entro onchange")
		partner = self._origin.id
		for order in self:
			if order.confirmacion_estado == True:
				fecha_hoy = str(datetime.now())[:10]
				this = self.env['res.partner'].browse(partner)
				val = {
					'partner_id':partner,
					'estado_afiliacion':order.estado_afiliacion,
					'fecha_cambio':fecha_hoy,
					'estado_anterior':this.estado_afiliacion
				}
				wizard = self.env['partner.afiliado'].create(val)
				this.write({
					'estado_afiliacion' : order.estado_afiliacion,
					'confirmacion_estado': False
					})
				order.confirmacion_estado = False