# -*- coding: utf-8 -*-

from openerp import models, fields, api, exceptions, _
import base64
import sys
from odoo.exceptions import UserError
import pprint
from odoo.exceptions import ValidationError

class stock_picking_type(models.Model):
    _inherit = 'stock.picking.type'
    seria_guia = fields.Many2one('ir.sequence', u'Serie de guía')


class stock_picking(models.Model):
    _inherit = 'stock.picking'
    campo_temp = fields.Boolean('tipo de picking', compute='calculate_tipo_pinking', store=False)
    numberg = fields.Char(u'Serie de guía')
    client_order_ref = fields.Char(u'Orden de Compra Cliente')
    serie_guia = fields.Many2one('ir.sequence', 'Serie de guia')

    @api.multi
    def do_new_transfer(self):
        if self.serie_guia:
            partner = self.partner_id or self.owner_id
            if not partner.nro_documento:
                raise ValidationError("El cliente no tienen numero de documento")
        res = super(stock_picking, self).do_new_transfer()
        return res

    @api.one
    @api.constrains('picking_type_id')
    def validate_partner_or_owner(self):
        if self.picking_type_id.code not in ('internal','mrp_operation'):
            if not self.partner_id and not self.owner_id:
                raise ValidationError("Necesita ingresar un partner o un propietario")


    @api.onchange('serie_guia')
    def changed_serie_guia(self):
        if self.serie_guia:
            self.refres_numg()
            # self.update_serie_next_guia()

    @api.one
    def _check_numberg(self):
        print 5
        res = True
        if self.picking_type_id.code == 'internal' or self.picking_type_id.code == 'outgoing':
            if self.picking_type_id.seria_guia:
                if self.numberg:
                    cadsql = """
						select count(*) as cantidad 
						from stock_picking 
						inner join stock_picking_type on stock_picking.picking_type_id = stock_picking_type.id
						where numberg='""" + self.numberg + """' and (stock_picking_type.code= 'internal' or stock_picking_type.code='outgoing') and stock_picking.state = 'done'
						"""
                    self._cr.execute(cadsql)
                    data = self._cr.dictfetchall()
                    if data[0]['cantidad'] != 0:
                        res = False
        return res

    @api.model
    def create(self, vals):
        if 'picking_type_id' in vals:
            pt = self.env['stock.picking.type'].search([('id', '=', vals['picking_type_id'])])
            if pt.code == 'internal' or pt.code == 'outgoing':
                if 'serie_guia' in vals:
                # if self.serie_guia:
                    res = ''
                    serie_guia = self.env['ir.sequence'].browse(vals['serie_guia'])
                    if serie_guia.prefix:
                        res = serie_guia.prefix
                    number = str(serie_guia.number_next_actual)
                    if serie_guia.padding:
                        number = number.rjust(serie_guia.padding, '0')

                    res = res + number
                    vals['numberg'] = res
                    # vals['serie_guia'] = pt.seria_guia.id
                if pt.seria_guia:
                    res = ''
                    if pt.seria_guia.prefix:
                        res = pt.seria_guia.prefix
                    number = str(pt.seria_guia.number_next_actual)
                    if pt.seria_guia.padding:
                        number = number.rjust(pt.seria_guia.padding, '0')

                    res = res + number
                    vals['numberg'] = res
                    vals['serie_guia'] = pt.seria_guia.id
            else:
                vals['numberg'] = False
        return super(stock_picking, self).create(vals)



    @api.multi
    def write(self, vals):
        if 'picking_type_id' in vals:
            pt = self.env['stock.picking.type'].search([('id', '=', vals['picking_type_id'])])
            if pt.code == 'internal' or pt.code == 'outgoing':

                if 'serie_guia' in vals:
                    serie_guia_id = vals['serie_guia']
                else:
                    serie_guia_id = self.serie_guia
                serie_guia = self.env['ir.sequence'].browse(serie_guia_id)

                if serie_guia:
                    if 'numberg' in vals:
                        res = self.makecurrentsequecenumber(serie_guia)
                        vals['numberg'] = res[0]
            else:
                vals['numberg'] = False

        ctx = dict(self._context or {})
        return super(stock_picking, self.with_context(ctx)).write(vals)

    @api.depends('campo_temp', 'numberg')
    @api.one
    def calculate_tipo_pinking(self):
        print 4
        culmple = False
        if self.picking_type_id:
            if self.picking_type_id.code == 'internal' or self.picking_type_id.code == 'outgoing':
                culmple = True

        self.campo_temp = culmple

    @api.one
    def makecurrentsequecenumber(self, sequence_act):
        print 3, sequence_act.number_next_actual, sequence_act.prefix, sequence_act.padding
        res = ''
        if sequence_act.prefix:
            res = sequence_act.prefix
        number = str(sequence_act.number_next_actual)
        if sequence_act.padding:
            number = number.rjust(sequence_act.padding, '0')

        res = res + number
        print 'aaaaa', res, number
        return res

    @api.depends('numberg')
    @api.one
    def refres_numg(self):
        if self.state == 'done':
            return
        self.numberg = False
        if self.state not in ['done', 'cancel']:
            if self.picking_type_id.code == 'internal' or self.picking_type_id.code == 'outgoing':
                if self.serie_guia:
                    res = self.makecurrentsequecenumber(self.serie_guia)
                    self.numberg = res[0]

    @api.depends('numberg')
    @api.onchange('picking_type_id')
    def _picking_type_change(self):
        self.numberg = False
        if self.picking_type_id.code == 'internal' or self.picking_type_id.code == 'outgoing':
            if self.picking_type_id.seria_guia:
                if not self.serie_guia:
                    self.serie_guia = self.picking_type_id.seria_guia
                    res = self.makecurrentsequecenumber(self.serie_guia)
                    self.numberg = res[0]

    @api.multi
    def do_transfer(self):
        res = super(stock_picking, self).do_transfer()
        self.update_serie_next_guia()
        return res

    @api.multi
    def update_serie_next_guia(self):
        if self.picking_type_id.code == 'internal' or self.picking_type_id.code == 'outgoing':
            if self.serie_guia:
                self.numberg = self.serie_guia.next_by_id()



class sale_order(models.Model):
    _inherit = 'sale.order'

    @api.multi
    def action_confirm(self):
        res = super(sale_order, self).action_confirm()
        for act in self:
            for picking in act.picking_ids:
                picking.client_order_ref = self.client_order_ref
                picking.refres_numg()
        return res
