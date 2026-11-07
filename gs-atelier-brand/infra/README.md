# Infra — WordPress + WooCommerce (OCI)

## Opinião sobre swap
**Sim, faça swap (2 GB).** Evita crash por falta de RAM na Micro.  
Não substitui memória: a loja fica mais lenta sob carga. Bom para montar e validar; depois suba para 2 GB+ RAM.

## Antes de instalar (OCI)
1. Anote o **IP público** da `maquina-shopify`
2. Security List / NSG: liberar **TCP 22, 80, 443** (0.0.0.0/0 ou seu IP no 22)
3. Conseguir SSH: `ssh -i sua-chave ubuntu@IP`
4. DNS (pode ser depois do SSL): `gsatelier.com.br` A → IP

## Instalar
```bash
sudo bash bootstrap-wordpress.sh
```

Variáveis opcionais:
```bash
sudo DOMAIN=gsatelier.com.br WP_ADMIN_EMAIL=seu@email.com bash bootstrap-wordpress.sh
```

Credenciais ficam em `/root/gsatelier-credentials.txt`.

## Depois
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d gsatelier.com.br -d www.gsatelier.com.br
```
