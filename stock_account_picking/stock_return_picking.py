# -*- coding: utf-8 -*-
from odoo import models, fields, api,exceptions , _
# from odoo.exceptions import UserError

class stock_picking_type(models.Model):
    _inherit = "stock.picking.type"
    journal_id = fields.Many2one('account.journal', 'Diario factura rectificativa')


class account_invoice(models.Model):
    _inherit = "account.invoice"

    @api.multi
    def button_compute(self, set_total=False):
        self.compute_taxes()
        for invoice in self:
            if set_total:
                invoice.check_total = invoice.amount_total
        return True

class stock_move(models.Model):
    _inherit = "stock.move"
    invoice_state =  fields.Selection([("invoiced", "Invoiced"),("2binvoiced", "Para ser abodano/facturado"),  ("none", "Not Applicable")], "Invoice Control", default="none", select=True, required=True, track_visibility='onchange',   states={'draft': [('readonly', False)]})

    def _create_invoice_line_from_vals(self, move, invoice_line_vals):
        print str(invoice_line_vals)
        return self.env['account.invoice.line'].create(invoice_line_vals)

    def _get_price_unit_invoice(self,move_line, type):
        if type in ('in_invoice', 'in_refund'):
            return move_line.price_unit
        #else:
        #    # If partner given, search price in its sale pricelist
        #    if move_line.partner_id and move_line.partner_id.property_product_pricelist:
        #        pricelist_obj = self.env["product.pricelist"]
        #        pricelist = move_line.partner_id.property_product_pricelist.id
        #        price = pricelist_obj.price_get([pricelist],
        #                move_line.product_id.id, move_line.product_uom_qty, move_line.partner_id.id, {
        #                    'uom': move_line.product_uom.id,
        #                    'date': move_line.date,
        #                    })[pricelist]
        #        if price:
        #            return price
        return move_line.product_id.list_price


    def _get_taxes(self, move):
        if move.origin_returned_move_id.purchase_line_id.taxes_id:
            return [tax.id for tax in move.origin_returned_move_id.purchase_line_id.taxes_id]
        return []

    def _get_invoice_line_vals(self,move, partner, inv_type):
        fp_obj = self.env['account.fiscal.position']
        if inv_type in ('out_invoice', 'out_refund'):
            account_id = move.product_id.property_account_income_id
            if not account_id:
                account_id = move.product_id.categ_id.property_account_income_categ_id
        else:
            account_id = move.product_id.property_account_expense_id
            if not account_id:
                account_id = move.product_id.categ_id.property_account_expense_categ_id
        # fiscal_position = partner.property_account_position
        account_id = fp_obj.map_account(account_id).id

        # set UoS if it's a sale and the picking doesn't have one
        uos_id = move.product_uom.id
        quantity = move.product_uom_qty
        # if move.product_uom_id:
        #     uos_id = move.product_uom_id.id
        #     quantity = move.quantity

        taxes_ids = self._get_taxes(move)

        return {
            'name': move.name,
            'account_id': account_id,
            'product_id': move.product_id.id,
            'uos_id': uos_id,
            'quantity': quantity,
            'price_unit': self._get_price_unit_invoice(move, inv_type),
            'invoice_line_tax_id': [(6, 0, taxes_ids)],
            'discount': 0.0,
            'account_analytic_id': False,
        }

    def get_code_from_locs(self,move, location_id=False,location_dest_id=False):
        code = 'internal'
        src_loc = location_id or move.location_id
        dest_loc = location_dest_id or move.location_dest_id
        if src_loc.usage == 'internal' and dest_loc.usage != 'internal':
            code = 'outgoing'
        if src_loc.usage != 'internal' and dest_loc.usage == 'internal':
            code = 'incoming'
        return code

    def _get_master_data(self,move,company):
        currency = company.currency_id.id
        partner = move.picking_id and move.picking_id.partner_id
        if partner:
            code = self.get_code_from_locs(move)
            if partner.property_product_pricelist and code == 'outgoing':
                currency = partner.property_product_pricelist.currency_id.id
        return partner,self.env.uid, currency

    def _get_moves_taxes(self,moves,inv_type):
        extra_move_tax = {}
        is_extra_move = {}
        for move in moves:
            if move.picking_id:
                is_extra_move[move.id] = True
                if not (move.picking_id, move.product_id) in extra_move_tax:
                    extra_move_tax[move.picking_id, move.product_id] = 0
            else:
                is_extra_move[move.id] = False
        return (is_extra_move, extra_move_tax)


class stock_picking(models.Model):
    _inherit = "stock.picking"
    invoice_state =  fields.Selection([("2binvoiced", u"Para ser abodano/facturado"),
            ("none", u"Sin facturación")], "Invoice Control",default='none')

    usage_destino = fields.Selection(related='location_dest_id.usage')


    def action_invoice_create(self,ids, journal_id, group=False, type='out_invoice'):
        todo = {}
        for picking in self.browse(ids):
            partner = picking.partner_id
            if group:
                key = partner
            else:
                key = picking.id
            for move in picking.move_lines:
                if move.invoice_state == '2binvoiced':
                    if (move.state != 'cancel') and not move.scrapped:
                        todo.setdefault(key, [])
                        todo[key].append(move)
        invoices = []
        for moves in todo.values():
            invoices += self._invoice_create_line(moves, journal_id, type)
        return invoices

    def _create_invoice_from_picking(self, picking, vals):
        invoice_obj = self.env['account.invoice']
        return invoice_obj.create(vals)

    def _get_invoice_vals(self,key, inv_type, journal_id, move):
        partner, currency_id, company_id, user_id = key
        if inv_type in ('out_invoice', 'out_refund'):
            account_id = partner.property_account_receivable_id.id
            payment_term = partner.property_payment_term_id.id or False
        else:
            account_id = partner.property_account_payable_id.id
            payment_term = partner.property_supplier_payment_term_id.id or False
        return {
            'origin': move.picking_id.name,
            'date_invoice': self.env.context.get('date_inv', False),
            'user_id': user_id,
            'partner_id': partner.id,
            'account_id': account_id,
            'payment_term': payment_term,
            'type': inv_type,
            'fiscal_position': partner.property_account_position_id.id,
            'company_id': company_id,
            'currency_id': currency_id,
            'journal_id': journal_id,
        }

    def _invoice_create_line(self,moves, journal_id, inv_type='out_invoice'):
        invoice_obj = self.env['account.invoice']
        move_obj = self.env['stock.move']
        invoices = {}
        is_extra_move, extra_move_tax = move_obj._get_moves_taxes(moves, inv_type)
        product_price_unit = {}
        for move in moves:
            company = move.company_id
            origin = move.picking_id.name
            partner, user_id, currency_id = move_obj._get_master_data(move, company)

            key = (partner, currency_id, company.id, user_id)
            invoice_vals = self._get_invoice_vals(key, inv_type, journal_id, move)
            if key not in invoices:
                # Get account and payment terms
                invoice_id = self._create_invoice_from_picking(move.picking_id, invoice_vals)
                invoices[key] = invoice_id
            else:

                invoice = invoices[key]
                if not invoice.origin or invoice_vals['origin'] not in invoice.origin.split(', '):
                    invoice_origin = filter(None, [invoice.origin, invoice_vals['origin']])
                    invoice.write({'origin': ', '.join(invoice_origin)})

            invoice_line_vals = move_obj._get_invoice_line_vals(move, partner, inv_type)
            invoice_line_vals['invoice_id'] = invoices[key].id
            invoice_line_vals['origin'] = origin
            if not is_extra_move[move.id]:
                product_price_unit[invoice_line_vals['product_id'], invoice_line_vals['uos_id']] = invoice_line_vals['price_unit']
            if is_extra_move[move.id] and (invoice_line_vals['product_id'], invoice_line_vals['uos_id']) in product_price_unit:
                invoice_line_vals['price_unit'] = product_price_unit[invoice_line_vals['product_id'], invoice_line_vals['uos_id']]
            if is_extra_move[move.id]:
                desc = (inv_type in ('out_invoice', 'out_refund') and move.product_id.product_tmpl_id.description_sale) or (inv_type in ('in_invoice','in_refund') and move.product_id.product_tmpl_id.description_purchase)
                invoice_line_vals['name'] += ' ' + desc if desc else ''
                if extra_move_tax[move.picking_id, move.product_id]:
                    invoice_line_vals['invoice_line_tax_id'] = extra_move_tax[move.picking_id, move.product_id]
                #the default product taxes
                elif (0, move.product_id) in extra_move_tax:
                    invoice_line_vals['invoice_line_tax_id'] = extra_move_tax[0, move.product_id]

            move_obj._create_invoice_line_from_vals(move, invoice_line_vals)
            move_obj.browse(move.id).write({'invoice_state': 'invoiced'})
        print('set toal' + str(invoices.values()))
        set_total = (inv_type in ('in_invoice', 'in_refund'))
        # invoice_obj.button_compute(invoices.values(),set_total)
        invoice_obj.button_compute(set_total)
        return invoices.values()

class stock_return_picking(models.TransientModel):
    _inherit = 'stock.return.picking'
    invoice_state = fields.Selection([('2binvoiced', u'Para ser abodano/facturado'), ('none', u"Sin facturación")], 'Invoicing',required=True, default="none")

    @api.multi
    def _create_returns(self):
        print('miquias')
        print(self.invoice_state)
        new_picking, picking_type_id = super(stock_return_picking, self)._create_returns()
        if self.invoice_state == '2binvoiced':
            picking = self.env["stock.picking"].browse(new_picking)
            move_ids = [x.id for x in picking.move_lines]
            self.env["stock.move"].browse(move_ids).write({'invoice_state': '2binvoiced'})
            picking.write({'invoice_state': '2binvoiced'})
        return new_picking, picking_type_id


# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
