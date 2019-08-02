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
    fecha_aproved_devolution = fields.Datetime('Fecha Retiro', defauld=datetime.today())
    user_proved = fields.Many2one('res.users', string='Usuario Aprueba')
    is_return_picking_compra = fields.Boolean(u'Es un retorno?', compute='calc_is_return_picking_compra')
    is_return_picking_venta = fields.Boolean(u'Es un retorno?', compute='calc_is_return_picking_venta')

    @api.one
    def aprovar_retorno(self):
        self.fecha_aproved_devolution = datetime.today()
        self.user_proved = self.env.user.id

    @api.one
    def calc_is_return_picking_compra(self):
        culmple = False
        if self.location_dest_id and self.location_dest_id.usage == 'supplier':
            culmple = True
        self.is_return_picking_compra = culmple

    @api.one
    def calc_is_return_picking_venta(self):
        culmple = False
        if self.location_id and self.location_id.usage == 'customer' and self.type_code_stock == 'incoming':
            culmple = True
        self.is_return_picking_venta = culmple

    @api.multi
    def do_new_transfer(self):
        if self.is_return_picking_compra==True and  not self.user_proved:
            raise ValidationError(_('Esta operacion, necesita aprobacion'))
        if self.is_return_picking_venta==True and  not self.user_proved:
            raise ValidationError(_('Esta operacion, necesita aprobacion'))
        res = super(stock_picking, self).do_new_transfer()
        return res

