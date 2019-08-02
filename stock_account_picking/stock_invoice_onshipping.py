# -*- coding: utf-8 -*-


from odoo import models, fields, api,exceptions , _
# from odoo.tools.translate import _
from odoo.exceptions import UserError

JOURNAL_TYPE_MAP = {
    ('outgoing', 'customer'): ['sale'],
    ('outgoing', 'supplier'): ['purchase_refund'],
    ('outgoing', 'transit'): ['sale', 'purchase_refund'],
    ('incoming', 'supplier'): ['purchase'],
    ('incoming', 'customer'): ['sale_refund'],
    ('incoming', 'transit'): ['purchase', 'sale_refund'],
}


class stock_invoice_onshipping(models.TransientModel):
    def _get_journal(self):
        picking = self.env['stock.picking'].browse(self.env.context['active_ids'])
        return  picking.picking_type_id.journal_id

    def _get_journal_type(self):
        pickings = self.env['stock.picking'].browse(self.env.context['active_ids'])
        pick = pickings and pickings[0]
        if not pick or not pick.move_lines:
            return 'sale'
        type = pick.picking_type_id.code
        usage = pick.move_lines[0].location_id.usage if type == 'incoming' else pick.move_lines[
            0].location_dest_id.usage
        return JOURNAL_TYPE_MAP.get((type, usage), ['sale'])[0]

    _name = "stock.invoice.onshipping"
    _description = "Stock Invoice Onshipping"
    journal_id = fields.Many2one('account.journal', 'Diario destino',default=_get_journal)
    journal_type = fields.Selection([('purchase_refund', 'Refund Purchase'), ('purchase', 'Create Supplier Invoice'),
                                     ('sale_refund', 'Refund Sale'), ('sale', 'Create Customer Invoice')],
                                    'Journal Type', readonly=True,default=_get_journal_type)
    group = fields.Boolean("Agrupar por empresa")
    invoice_date = fields.Date('Invoice Date')


    def view_init(self,fields):
        res = super(stock_invoice_onshipping, self).view_init(fields)
        pick_obj = self.env['stock.picking']
        count = 0
        active_ids = self.env.context['active_ids']
        for pick in pick_obj.browse(active_ids):
            if pick.invoice_state != '2binvoiced':
                count += 1
        if len(active_ids) == count:
            raise UserError(_("None of these picking lists require invoicing."))
        return res

    @api.multi
    def open_invoice(self):
        invoice_id = self.create_invoice()
        parametro = self.env['main.parameter'].search([], limit=1)
        
        view_rec = False
        if not invoice_id:
            raise UserError(_("No invoice created!"))
        invoice_id = invoice_id[0]
        if parametro and parametro.type_document_id:
            invoice_id.write({'it_type_document':parametro.type_document_id.id})

        if self.journal_id.type == 'sale':
            pick = self.env['stock.picking'].browse(self.env.context['active_id'])

            if pick.location_id.usage == 'customer':
                invoice_id.write({'type':'out_refund'})
                view_rec = self.env['ir.model.data'].get_object_reference('account', 'invoice_form')

            if pick.location_dest_id.usage == 'customer':
                invoice_id.write({'type':'out_invoice'})
                view_rec = self.env['ir.model.data'].get_object_reference('account', 'invoice_form')

        if self.journal_id.type == 'purchase':
            pick = self.env['stock.picking'].browse(self.env.context['active_id'])

            if pick.location_id.usage == 'supplier':
                invoice_id.write({'type':'in_invoice'})
                view_rec = self.env['ir.model.data'].get_object_reference('account', 'invoice_supplier_form')

            if pick.location_dest_id.usage == 'supplier':
                invoice_id.write({'type':'in_refund'})
                view_rec = self.env['ir.model.data'].get_object_reference('account', 'invoice_supplier_form')


        
        view_id = view_rec and view_rec[1] or False     
        return {
            'view_id': [view_id],
            'type': 'ir.actions.act_window',
            'res_model': 'account.invoice',
            'res_id': invoice_id.id,
            'view_type': 'form',
            'view_mode': 'form',
        }


    @api.multi
    def create_invoice(self):
        context = dict(self.env.context or {})
        picking_pool = self.env['stock.picking']
        data = self.browse(self.ids[0])
        journal2type = {'sale': 'out_invoice', 'purchase': 'in_invoice', 'sale_refund': 'out_refund',
                        'purchase_refund': 'in_refund'}
        inv_type = journal2type.get(data.journal_type) or 'out_invoice'

        active_ids = context.get('active_ids', [])
        res = picking_pool.action_invoice_create(active_ids,
                                                 journal_id=self.journal_id.id,
                                                 group=self.group,
                                                 type=inv_type)
        return res