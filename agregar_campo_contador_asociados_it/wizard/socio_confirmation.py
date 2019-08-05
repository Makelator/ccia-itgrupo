# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

from odoo import api, fields, models, _
from odoo.exceptions import UserError


class SocioConfirmation(models.TransientModel):
	_name = 'estado.confirmation.socio'
	_description = 'Confirmar Estado Asociado'

	res_partner = fields.Many2one('res.partner')

	@api.model
	def default_get(self, fields):
		res = super(SocioConfirmation, self).default_get(fields)
		if not res.get('res_partner') and self._context.get('active_id'):
			res['res_partner'] = self._context['active_id']
		return res

	@api.multi
	def process(self):
		self.ensure_one()
		for order in self.res_partner:
			order.confirmacion_estado = True
		return self.res_partner.confirmar_estado()
