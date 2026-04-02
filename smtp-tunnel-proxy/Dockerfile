# Use a slim Python image for a smaller footprint
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies (curl for health checks, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application files
COPY . .

# Ensure the start script is executable
RUN chmod +x start.sh

# Expose the SMTP port
EXPOSE 587

# Use the startup script to handle dynamic configuration
CMD ["./start.sh"]
