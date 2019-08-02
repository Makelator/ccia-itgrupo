# -*- coding: utf-8 -*-

from collections import namedtuple
import json
import time

from odoo import api, fields, models, _
from odoo.tools import DEFAULT_SERVER_DATETIME_FORMAT
from odoo.tools.float_utils import float_compare
from odoo.addons.procurement.models import procurement
from odoo.exceptions import UserError


class ProductCategory(models.Model):
    _inherit = "product.category"


    einvoice_05 = fields.Many2one('einvoice.catalog.05', 'Codigo de existencia')


class product_template(models.Model):
	_inherit = 'product.template'
	
	unidad_kardex = fields.Many2one('product.uom',string="Unidad de Producto Kardex")