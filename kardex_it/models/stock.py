# -*- coding: utf-8 -*-

from collections import namedtuple
import json
import time

from odoo import api, fields, models, _
from odoo.tools import DEFAULT_SERVER_DATETIME_FORMAT
from odoo.tools.float_utils import float_compare
from odoo.addons.procurement.models import procurement
from odoo.exceptions import UserError


class StockMove(models.Model):
    _inherit = "stock.move"

    analitic_id = fields.Many2one('account.analytic.account','Cta. Analitica')
    linked_expense = fields.Float('Gasto Vinculado',digit=(12,2))