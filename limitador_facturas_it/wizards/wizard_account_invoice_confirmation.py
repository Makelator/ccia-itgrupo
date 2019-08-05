# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

from odoo import api, fields, models, _
from odoo.exceptions import UserError


class WizardAccountInvoiceConfirmation(models.TransientModel):
    _name = 'account.invoice.limit.confirmation'
    _description = 'Confirmar Factura'

    account_invoice_id = fields.Many2one('account.invoice')

    @api.model
    def default_get(self, fields):
        res = super(WizardAccountInvoiceConfirmation, self).default_get(fields)
        if not res.get('account_invoice_id') and self._context.get('active_id'):
            res['account_invoice_id'] = self._context['active_id']
        return res

    @api.multi
    def process(self):
        self.ensure_one()
        self.account_invoice_id.control_limite_factura_excedida_aceptada = True
        return self.account_invoice_id.action_invoice_open()