Spree.ready(function () {
  'use strict';

  function formatProduct(product) {
    return Select2.util.escapeMarkup(product.name);
  }

  if ($('#auction_product_id').length > 0) {
    $('#auction_product_id').select2({
      placeholder: Spree.translations.product_placeholder,
      multiple: false,
      initSelection: function (element, callback) {
        return Spree.ajax({
          url: Spree.routes.admin_product_search,
          data: { ids: element.val() },
          type: 'get',
          success: function(data) {
            return callback(data.products[0]);
          }
        });
      },

      ajax: {
        url: Spree.routes.admin_product_search,
        datatype: 'json',
        params: { "headers": { "X-Spree-Token": Spree.api_key } },
        data: function (term, page) {
          return {
            q: {
              name_cont: term,
              variants_including_master_sku_start: term,
              m: 'or'
            },
            token: Spree.api_key,
            page: page
          };
        },
        results: function (data, page) {
          var products = data.products ? data.products : [];
          return {
            results: products,
            more: (data.current_page * data.per_page) < data.total_count
          };
        }
      },
      formatResult: formatProduct,
      formatSelection: formatProduct
    });
  }
});
