# Generatore di AppImage per il patcher di SpaghettiProject
### Prerequisiti
Assicurati che la tua distribuzione supporti l'esecuzione di file AppImage. La maggior parte delle distribuzioni moderne lo fa nativamente, ma alcune potrebbero richiedere l'installazione del pacchetto `libfuse`.


## Perché?
Il progetto è nato per risolvere il problema di compatibilità con le dipendenze necessarie al patcher, come OpenSSL 1.0 e .NET 5.0, che non sono più disponibili nei repository ufficiali di molte distribuzioni Linux. La creazione di un'AppImage permette di utilizzare il patcher su più distribuzioni.

## Come eseguire il file generato?
- **Via interfaccia grafica**: Fai doppio click sul file (su alcuni desktop è click singolo)
- **Via terminale**: `./ItalianPatcherByUSPLinux.AppImage`

## Guida alla compilazione
### Dipendenze
- Perl
- curl
- imagemagick
- tar

### Opzione 1: Comando Singolo
Usa questo comando per generare l'appimage:  
```bash
curl -s "https://raw.githubusercontent.com/demperor-music/SpaghettiProjectAppImageGenerator/refs/heads/main/PatcherAppImageGenerator.sh" | bash
```

### Opzione 2: Scarica il file ed eseguilo
1. Scarica il file `.sh` dalla repository.  
2. Rendilo eseguibile:  
   - **Via interfaccia grafica (GNOME)**:  
     - Fai clic destro sul file, vai su "Proprietà", e abilita l'opzione "Esegui come programma".
   - **Via terminale**:  
     ```bash
     chmod +x PatcherAppImageGenerator.sh
     ```    
3. Avvia lo script:    
   - **Via interfaccia grafica (GNOME)**:  
     - Fai clic destro sul file e seleziona "Esegui come programma".
   - **Via terminale**:  
     ```bash
     ./PatcherAppImageGenerator.sh
     ```
