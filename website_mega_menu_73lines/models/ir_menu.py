# -*- coding: utf-8 -*-
# Part of Odoo Module Developed by 73lines
# See LICENSE file for full copyright and licensing details.

from odoo import api, fields, models
from odoo.tools.translate import html_translate


class Menu(models.Model):
    _inherit = "website.menu"

    is_mega_menu = fields.Boolean(string='Is Mega Menu ?')
    submenu_view = fields.Html(string='SubMenu View', translate=html_translate, sanitize_attributes=False)

    @api.multi
    def open_template(self):
        self.ensure_one()
        return {
            'type': 'ir.actions.act_url',
            'target': 'self',
            'url': '/megamenu/edit/%d' % self.id
        }
