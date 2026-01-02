FROM frappe/erpnext:v15.93.1

# Switch to frappe user
USER frappe

# Copy the custom app into the image
COPY --chown=frappe:frappe apps/custom_app /home/frappe/frappe-bench/apps/custom_app

# Install the app
RUN pip install --no-cache-dir -e /home/frappe/frappe-bench/apps/custom_app
