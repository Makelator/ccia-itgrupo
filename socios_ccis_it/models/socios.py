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
values = {}

import datetime

class sale_order_inherit(models.Model):
	_name = 'partner.afiliado'

	partner_id = fields.Many2one('res.partner','Cliente')
	estado_afiliacion = fields.Selection( [('no_afiliado','No Afiliado'),('afiliado','Afiliado'),('proceso','En Proceso de Afiliacion')],'Estado de Afiliacion',default='proceso')
	estado_anterior = fields.Selection( [('no_afiliado','No Afiliado'),('afiliado','Afiliado'),('proceso','En Proceso de Afiliacion')],'Estado de Anterior',default='proceso')
	fecha_cambio = fields.Datetime('Fecha de Cambio de Estado')
