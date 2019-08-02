# -*- coding: utf-8 -*-
# Part of Odoo Module Developed by 73lines
# See LICENSE file for full copyright and licensing details.

from odoo import http
from odoo.http import request


class WebsiteMegaMenu(http.Controller):

    @http.route(["/megamenu/edit/<model('website.menu'):menu>"], type='http', auth="user", website=True)
    def template_view(self, menu, **post):
        values = {'template': menu}
        return request.render('website_mega_menu_73lines.menu_template', values)
