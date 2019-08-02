# -*- coding: utf-8 -*-

from collections import namedtuple
import json
import time

from odoo import api, fields, models, _
from odoo.tools import DEFAULT_SERVER_DATETIME_FORMAT
from odoo.tools.float_utils import float_compare
from odoo.addons.procurement.models import procurement
from odoo.exceptions import UserError


class PickingType(models.Model):
    _inherit = "main.parameter"

    prefijo = fields.Char('Prefijo', size=12)

    etiqueta_analitica =  fields.Many2one('account.analytic.tag', 'Etiqueta analitica')