FROM postgres:15.3-bookworm

# Here's the critical bit!
RUN sed -i 's/#huge_pages = try/huge_pages = off/' \
    /usr/share/postgresql/postgresql.conf.sample
