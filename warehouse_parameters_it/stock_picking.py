# -*- coding: utf-8 -*-

from openerp import models, fields, api, exceptions, _
import base64
import sys
from odoo.exceptions import UserError
from odoo.exceptions import ValidationError
from datetime import date
from datetime import datetime

class stock_picking(models.Model):
    _inherit = 'stock.picking'

    @api.multi
    def do_new_transfer(self):
        self.validate_limit_line()
        parametro = parameters = self.env['warehouse.parameters'].search([], limit=1)
        if str(self.fecha_kardex) != str(date.today()) and not 'a' in self.env.context and parametro.validar_fecha_albaran:
            view = self.env.ref('warehouse_parameters_it.view_confirm_date_picking_form')
            wiz = self.env['confirm.date.picking'].create({'pick_id': self.id})
            return {
                'name': _('Cambiar fecha de kardex'),
                'type': 'ir.actions.act_window',
                'view_type': 'form',
                'view_mode': 'form',
                'res_model': 'confirm.date.picking',
                'views': [(view.id, 'form')],
                'view_id': view.id,
                'target': 'new',
                'res_id': wiz.id,
                'context': self.env.context,
            }

        return super(stock_picking, self).do_new_transfer()

    @api.one
    def validate_limit_line(self):
        parameters  = self.env['warehouse.parameters'].search([],limit=1)
        if self.type_code_stock != 'outgoing' or not parameters.limit_line_albaran:
            return
        limit_lines = parameters.limit_line_albaran
        lines_operation = self.env['stock.pack.operation'].search([('picking_id','=',self.id),('qty_done','>',0)])
        lines_operation_to_zero = self.env['stock.pack.operation'].search([('picking_id','=',self.id),('qty_done','=',0)])
        lines_view = len(self.pack_operation_product_ids)
        if len(lines_operation)>limit_lines or (len(lines_operation_to_zero)==lines_view and lines_view > limit_lines):
            raise ValidationError('La cantidad de items del albarán supera el limite ('+str(limit_lines)+') permitido para la guía de remisión.')
