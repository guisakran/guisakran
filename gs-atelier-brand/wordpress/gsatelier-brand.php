<?php
/**
 * Plugin Name: GS Atelier Brand
 */
add_action("wp_enqueue_scripts", function () {
  wp_enqueue_style(
    "gsatelier-fonts",
    "https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@400;500;600&family=DM+Sans:opsz,wght@9..40,300;9..40,400;9..40,500&display=swap",
    [],
    null
  );
  $css = <<<CSS
:root{
  --theme-font-family:"DM Sans",sans-serif!important;
  --theme-font-stack-default:"DM Sans",sans-serif!important;
  --theme-palette-color-1:#111111!important;
  --theme-palette-color-2:#1B2430!important;
  --theme-button-background-initial-color:#111111!important;
  --theme-button-background-hover-color:#1B2430!important;
  --theme-link-initial-color:#111111!important;
}
body,.entry-content,.woocommerce,button,input,select,textarea{font-family:"DM Sans",sans-serif!important;background:#F7F5F1!important;color:#111;}
h1,h2,h3,h4,h5,h6,.site-title,.wp-block-heading,.product_title,.woocommerce-loop-product__title{
  font-family:"Cormorant Garamond",serif!important;font-weight:500!important;letter-spacing:.08em;
}
.button,.woocommerce a.button,.woocommerce button.button,.wp-element-button{
  font-family:"DM Sans",sans-serif!important;border-radius:0!important;letter-spacing:.14em!important;
  text-transform:uppercase!important;font-size:11px!important;font-weight:500!important;
}
.woocommerce span.onsale{display:none!important;}
.site-branding .site-title-container,.site-branding .site-title,.site-branding .site-description{display:none!important;}
.site-branding .site-logo-container img.default-logo{max-height:42px!important;width:auto!important;}
.woocommerce ul.products li.product{text-align:center;margin:0 0 2.2rem!important;background:transparent!important;box-shadow:none!important;border:0!important;}
.woocommerce ul.products li.product a img{margin-bottom:.9rem;background:#F2EFE9;}
.woocommerce ul.products li.product .woocommerce-loop-product__title{font-size:14px!important;letter-spacing:.12em!important;text-transform:uppercase;margin:.4rem 0 .25rem!important;}
.woocommerce ul.products li.product .price{font-size:13px!important;color:#3A4A5C!important;font-weight:400!important;}
#header .ct-header [data-row*="middle"]{--height:88px!important;}
.header-menu-1 .menu > li > a{letter-spacing:.14em!important;font-size:11px!important;font-weight:500!important;text-transform:uppercase!important;}
.gs-topbar{background:#111;color:#fff;text-align:center;font-size:11px;letter-spacing:.18em;text-transform:uppercase;padding:.7rem 1rem;position:relative;z-index:50;}
.home .entry-header,.page-id-15 .entry-header{display:none!important;}
.entry-header .page-title{letter-spacing:.14em;text-transform:uppercase;font-size:1rem!important;}
.single-product .product_title{letter-spacing:.1em;text-transform:uppercase;}

/* Garderobe-inspired editorial layout */
.home #main-container > .hero-section,
.home .ct-container-full > .hero-section{display:none!important;}
.gs-hero{margin:0!important;max-width:100%!important;}
.gs-hero .wp-block-cover{border-radius:0!important;}
.gs-hero .wp-block-cover__inner-container{
  animation:gsFadeUp .9s ease-out both;
}
.entry-content .wp-block-image img,
.entry-content .wp-block-cover__image-background{
  transition:transform 1.1s cubic-bezier(.2,.7,.2,1);
}
.entry-content .wp-block-column:hover .wp-block-image img{
  transform:scale(1.035);
}
.entry-content .wp-block-columns .wp-block-column .wp-block-image{
  overflow:hidden;margin-bottom:.85rem;
}
.entry-content .wp-block-columns .wp-block-column .wp-block-image img{
  width:100%;height:340px;object-fit:cover;display:block;
}
.gs-lookbook.wp-block-gallery{gap:1rem!important;}
.gs-lookbook .wp-block-image{overflow:hidden;}
.gs-lookbook .wp-block-image img{
  height:420px;object-fit:cover;width:100%;
  transition:transform 1.1s cubic-bezier(.2,.7,.2,1),filter .6s ease;
  filter:saturate(.92) contrast(1.02);
}
.gs-lookbook .wp-block-image:hover img{transform:scale(1.04);filter:saturate(1) contrast(1.05);}
@keyframes gsFadeUp{
  from{opacity:0;transform:translateY(18px)}
  to{opacity:1;transform:translateY(0)}
}
@media (max-width:781px){
  .entry-content .wp-block-columns .wp-block-column .wp-block-image img{height:280px;}
  .gs-lookbook .wp-block-image img{height:300px;}
  .gs-hero .wp-block-cover{min-height:78vh!important;}
}
CSS;
  wp_add_inline_style("gsatelier-fonts", $css);
}, 40);

add_action("wp_body_open", function () {
  if (is_admin()) return;
  echo "<div class=\"gs-topbar\">Frete grátis acima de R\$ 799</div>";
}, 5);

add_filter("woocommerce_product_add_to_cart_text", function () { return "Selecionar"; });
add_filter("woocommerce_product_single_add_to_cart_text", function () { return "Adicionar à sacola"; });
add_filter("woocommerce_out_of_stock_message", function () { return "Esgotada nesta tiragem"; });
