# -*- encoding: utf-8 -*-
{
    'name': 'Kardex',
    'version': '1.0',
    'author': 'ITGRUPO-COMPATIBLE-BO',
    'website': '',
    'category': 'account',
    'depends': ['import_base_it','stock_account','product','stock','mrp','purchase_requisition','kardex_campos_it','account_move_advanceadd_it','sale_stock','account_parametros_it'],
    'description': """KARDEX""",
    'demo': [],
    'data': [
        'views/einvoice_view.xml',
        'views/stock_picking_views.xml',
        'views/product_views.xml',
        'views/stock_warehouse_view.xml', 
        'views/main_parameter_view.xml', 
        'views/product_uom_views.xml',
        'views/invoice_view.xml',
        'views/purchase_order_view.xml',
        'views/account_move_view.xml',
        'wizard/make_kardex_view.xml',
        'wizard/kardex_vs_account_line_view.xml',
        'data/einvoice_12_data.xml',
        'data/einvoice_05_data.xml',
        'data/einvoice_13_data.xml',

    ],
    'auto_install': False,
    'installable': True
}
