
FROM ubuntu:14.04 
RUN set -x; \
        apt-get update \
        && apt-get install -y \
            postgresql-client \
            ca-certificates \
            curl \
            node-less \
            node-clean-css \
            python-dateutil python-feedparser \
            python-ldap python-libxslt1 python-lxml \
            python-mako python-openid python-psycopg2 \
            python-pybabel python-pychart python-pydot \
            python-pyparsing python-reportlab python-simplejson \
            python-tz python-vatnumber python-vobject \
            python-webdav python-werkzeug python-xlwt \
            python-yaml python-zsi python-docutils \
            python-psutil python-mock python-unittest2 \
            python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil \
            python-pip python-gevent \
        && pip install \
            pyserial qrcode pytz jcconv \
            gdata passlib \
            gevent gevent_psycopg2 psycogreen \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm
RUN pip install --pre pyusb
# Install wkhtmltopdf Package 
ADD http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb wkhtmltox.deb
RUN dpkg --force-depends -i wkhtmltox.deb
RUN cp /usr/local/bin/wkhtmltopdf /usr/bin
RUN cp /usr/local/bin/wkhtmltoimage /usr/bin
RUN rm wkhtmltox.deb
# Create Odoo System User 
RUN adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --gecos 'ODOO' --group odoo
#Create Log directory ----" 
RUN mkdir -p /var/log/odoo
RUN chown odoo:odoo /var/log/odoo
# Install Odoo 
# ADD https://nightly.odoo.com/9.0/nightly/src/odoo_9.0c.latest.tar.gz /opt/odoo/odoo.tar.gz
ADD https://github.com/kedaerp/odoo9/archive/v1.0.tar.gz /opt/odoo/odoo.tar.gz
RUN chown odoo:odoo /opt/odoo/odoo.tar.gz
# Change User to Odoo 
USER odoo 
RUN tar -xvzf /opt/odoo/odoo.tar.gz -C /opt/odoo --strip-components 1
RUN /bin/bash -c "mkdir -p /opt/odoo/addons" && \
    cd /opt/odoo/ && \
    rm /opt/odoo/odoo.tar.gz
# Execution environment 
USER 0 # Copy entrypoint script , Odoo Service script and Odoo configuration file 
COPY ./entrypoint.sh /
COPY ./openerp-server.conf /etc/
COPY ./openerp-server /etc/init.d/
RUN chown odoo:odoo /etc/openerp-server.conf
RUN chmod 640 /etc/openerp-server.conf
RUN chmod 755 /etc/init.d/openerp-server
RUN chown root: /etc/init.d/openerp-server
# Create service sudo service odoo-server start 
RUN update-rc.d openerp-server defaults
# Start odoo service 
RUN service openerp-server start
# Mount /opt/odoo to allow restoring filestore and /mnt/extra-addons for users addons 
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/opt/odoo", "/mnt/extra-addons"]
# Expose Odoo services 
EXPOSE 8069 8071 # Set the default config file 
ENV OPENERP_SERVER /etc/openerp-server.conf # Set default user when running the container 
USER odoo ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/odoo/openerp-server"]
