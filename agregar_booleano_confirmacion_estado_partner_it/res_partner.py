# -*- coding: utf-8 -*-
from odoo.tools.misc import DEFAULT_SERVER_DATETIME_FORMAT
from openerp.exceptions import Warning
import time
from odoo.exceptions import UserError
import odoo.addons.decimal_precision as dp
from openerp.osv import osv
import base64
from odoo import models, fields, api
from datetime import datetime, timedelta
import codecs

class ResPartner(models.Model):
	_inherit = 'res.partner'

	confirmacion_estado = fields.Boolean(string='¿Cambiar Estado de Asociado?',default=False)