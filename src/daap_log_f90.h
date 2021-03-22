! fortran header

void daapinit_(char *app_name, int len);

void daapfinalize_(void);

void daaplogwrite_(char *message, int len);

void daaplogheartbeat_(void);

void daaplogjobstart_(void);

void daaplogjobduration_(void);

void daaplogjobend_(void);
