FROM frappe/erpnext:v15.93.1

# Switch to frappe user
USER frappe

# Copy the custom app into the image
COPY --chown=frappe:frappe apps/custom_app /home/frappe/frappe-bench/apps/custom_app

# Install the app using the bench's virtual environment
RUN ./env/bin/pip install --no-cache-dir -e ./apps/custom_app
