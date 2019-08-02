# -*- coding: utf-8 -*-
# Part of Odoo. See LICENSE file for full copyright and licensing details.

{
    'name': 'Odoo Settings Dashboard IT',
    'version': '1.0',
    'author':'ITGRUPO-COMPATIBLE-BO',
    'summary': 'Quick actions for installing new app, adding users, completing planners, etc.',
    'category': 'Extra Tools',
    'description':
    """
DashBoard ITGRUPO
        """,
    'data': [
        'views/dashboard_views.xml',
        'views/dashboard_templates.xml',
    ],
    'depends': ['web_settings_dashboard'],
    'qweb': ['static/src/xml/dashboard.xml'],
    'auto_install': False,
}
