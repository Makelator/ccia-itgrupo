# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

from odoo import api, fields, tools, models, _
from odoo.exceptions import UserError


class ProductUoMCategory(models.Model):
    _inherit = 'product.uom'

    einvoice_06 = fields.Many2one('einvoice.catalog.13', 'Codigo unidad de medida')
