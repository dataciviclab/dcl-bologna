#!/usr/bin/env python3
"""Compila i campi editoriali del registry dcl-bologna (tutti i dataset).

name/description/source per dataset + descrizioni delle colonne chiave.
Da eseguire dalla root del repo: python3 scripts/enrich_registry.py
"""
import json

PATH = 'registry/registry.json'

# name, description, source per dataset
META = {
    'bolognawifi_matrice': (
        'Matrice spostamenti pedonali WiFi',
        'Flussi di spostamento tra zone WiFi pubbliche (2021-2025) — proxy della mobilità pedonale per zona e ora',
        'OpenData Comune di Bologna — BolognaWiFi'),
    'centraline_aria': (
        'Centraline qualità dell\'aria',
        'Rilevazioni orarie degli inquinanti atmosferici per stazione di monitoraggio',
        'OpenData Comune di Bologna — Arpae'),
    'colonnine_bici': (
        'Conta-bici per colonnina',
        'Passaggi di biciclette rilevati dalle colonnine conta-bici, per via e direzione',
        'OpenData Comune di Bologna — Mobilità sostenibile'),
    'convivenze': (
        'Popolazione in convivenza',
        'Residenti in convivenza (case di riposo, studentati, istituti) per quartiere e tipologia',
        'OpenData Comune di Bologna — Ufficio di Statistica'),
    'emigrati_destinazione': (
        'Emigrati per destinazione',
        'Emigrati dal Comune per quartiere e destinazione (comune, regione, estero)',
        'OpenData Comune di Bologna — Ufficio di Statistica'),
    'famiglie_tipologia': (
        'Famiglie per tipologia',
        'Famiglie per tipologia, quartiere e caratteristiche del capofamiglia',
        'OpenData Comune di Bologna — Ufficio di Statistica'),
    'incarichi': (
        'Incarichi di collaborazione Comune',
        'Incarichi di collaborazione, consulenza e lavoro del Comune di Bologna',
        'OpenData Comune di Bologna — Amministrazione trasparente'),
    'indici_fragilita': (
        'Indici di fragilità per area statistica',
        'Indici sintetici di fragilità demografica, sociale ed economica per area statistica',
        'OpenData Comune di Bologna — Ufficio di Statistica'),
    'popolazione_quartiere': (
        'Popolazione per quartiere',
        'Popolazione residente per quartiere, zona, età e cittadinanza (serie 1986-2024)',
        'OpenData Comune di Bologna — Ufficio di Statistica'),
    'precipitazioni_bologna': (
        'Precipitazioni giornaliere',
        'Precipitazioni giornaliere in millimetri, con stagione di riferimento',
        'OpenData Comune di Bologna — Arpae'),
    'reddito_mediano': (
        'Reddito mediano per area statistica',
        'Reddito imponibile mediano e numero contribuenti per area statistica (2016-2024)',
        'OpenData Comune di Bologna — Ufficio di Statistica'),
    'spire_traffico': (
        'Traffico fuori ZTL (spire)',
        'Passaggi veicolari sulle strade fuori ZTL rilevati dalle spire, per via e fascia oraria',
        'OpenData Comune di Bologna — Mobilità sostenibile'),
    'temperature_bologna': (
        'Temperature giornaliere',
        'Temperature media, minima e massima giornaliera, con stagione di riferimento',
        'OpenData Comune di Bologna — Arpae'),
    'varchi_ztl': (
        'Passaggi veicolari ZTL',
        'Passaggi veicolari ai varchi ZTL per tipologia veicolo, direzione e ora',
        'OpenData Comune di Bologna — Mobilità sostenibile'),
}

# descrizioni colonne chiave per dataset
COLS = {
    'bolognawifi_matrice': {
        'anno': 'Anno di riferimento', 'data': 'Data della misurazione',
        'ora': 'Ora della misurazione', 'giorno_num': 'Numero giorno settimana (1=Lunedì)',
        'giorno_label': 'Giorno settimana', 'id_origine': 'Zona di origine',
        'label_origine': 'Nome zona di origine', 'id_destinazione': 'Zona di destinazione',
        'label_destinazione': 'Nome zona di destinazione', 'totale': 'Flusso di dispositivi',
        'percentile_50': 'Percentile 50 della distribuzione',
    },
    'centraline_aria': {
        'anno': 'Anno di riferimento', 'reftime': 'Data e ora rilevazione',
        'stazione': 'Nome stazione di monitoraggio', 'agente_atm': 'Inquinante misurato',
        'value': 'Concentrazione rilevata',
    },    'colonnine_bici': {
        'anno': 'Anno di riferimento', 'data': 'Data e ora rilevazione',
        'colonnina': 'Nome colonnina', 'via': 'Via della colonnina',
        'quartiere': 'Quartiere', 'zona': 'Zona',
        'direzione_centro': 'Passaggi verso il centro', 'direzione_periferia': 'Passaggi verso la periferia',
        'totale': 'Totale passaggi',
    },
    'convivenze': {
        'anno': 'Anno di riferimento', 'quartiere': 'Quartiere', 'zona': 'Zona',
        'dimensione': 'Dimensione della convivenza', 'cittadinanza': 'Cittadinanza',
        'residenti': 'Residenti in convivenza',
    },
    'emigrati_destinazione': {
        'anno': 'Anno di riferimento', 'quartiere': 'Quartiere di partenza',
        'destinazione_comuni_regioni': 'Destinazione (comune o regione)',
        'destinazione_comuni_e_aree_italia': 'Destinazione dettagliata',
        'sesso': 'Sesso', 'numero_emigrati': 'Numero di emigrati',
    },
    'famiglie_tipologia': {
        'anno': 'Anno di riferimento', 'quartiere': 'Quartiere', 'zona': 'Zona',
        'tipo_capofamiglia': 'Tipologia del capofamiglia', 'eta': 'Età capofamiglia',
        'cittadinanza_del_capofamiglia': 'Cittadinanza del capofamiglia',
        'sesso': 'Sesso capofamiglia', 'numero_famiglie': 'Numero di famiglie',
    },
    'incarichi': {
        'id': 'Identificativo incarico', 'anno': 'Anno di riferimento',
        'anno_pg_atto': 'Anno protocollo atto', 'durata_dal': 'Data inizio incarico',
        'durata_al': 'Data fine incarico', 'oggetto': 'Oggetto dell\'incarico',
        'classificazione_incarichi': 'Classificazione', 'importo_euro': 'Importo in euro',
        'settore_dipartimento_area': 'Settore del Comune', 'servizio': 'Servizio',
        'dirigente': 'Dirigente', 'responsabile': 'Responsabile',
        'ragione_sociale': 'Soggetto incaricato', 'partita_iva': 'Partita IVA del soggetto',
        'codice_fiscale': 'Codice fiscale del soggetto', 'curriculum_link': 'Link al curriculum',
    },
    'indici_fragilita': {
        'anno': 'Anno di riferimento', 'area_statistica': 'Area statistica',
        'quartiere': 'Quartiere', 'zona_pross': 'Zona di prossimità',
        'frag_demo': 'Indice fragilità demografica', 'frag_soc': 'Indice fragilità sociale',
        'frag_econ': 'Indice fragilità economica', 'frag_compl': 'Indice fragilità complessiva',
        'cluster_an': 'Cluster gerarchico della fonte', 'rmpe_fam': 'Reddito medio famiglie',
        'pop_res': 'Popolazione residente', 'peraffit': 'Quota famiglie in affitto',
        'soli_65': 'Quota over 65 soli', 'perc_laur': 'Quota laureati',
    },
    'popolazione_quartiere': {
        'anno': 'Anno di riferimento', 'quartiere': 'Quartiere', 'zona': 'Zona',
        'cittadinanza': 'Cittadinanza', 'sesso': 'Sesso', 'eta_singolo': 'Età singola',
        'eta_grandi': 'Grande classe di età', 'residenti': 'Popolazione residente',
    },
    'precipitazioni_bologna': {
        'date': 'Data', 'pioggia_mm': 'Precipitazione in millimetri', 'stagione': 'Stagione',
    },
    'reddito_mediano': {
        'anno': 'Anno di riferimento', 'area_statistica': 'Area statistica',
        'reddito_imponibile_mediano': 'Reddito imponibile mediano (euro correnti)',
        'numero_contribuenti': 'Numero contribuenti residenti',
    },
    'spire_traffico': {
        'anno': 'Anno di riferimento', 'data': 'Data', 'nome_via': 'Via',
        'id_uni': 'Identificativo spira', 'tipologia': 'Tipologia rilevatore',
        'direzione': 'Direzione', 'fascia_oraria': 'Fascia oraria',
        'ora_inizio': 'Ora di inizio fascia', 'passaggi': 'Passaggi veicolari',
        'livello': 'Livello di flusso',
    },
    'temperature_bologna': {
        'date': 'Data', 'avg': 'Temperatura media', 'max': 'Temperatura massima',
        'min': 'Temperatura minima', 'stagione': 'Stagione',
    },
    'varchi_ztl': {
        'anno': 'Anno di riferimento', 'data': 'Data e ora', 'varco': 'Numero varco',
        'nome_varco': 'Nome varco', 'direzione': 'Direzione di controllo',
        'totale_passaggi': 'Totale passaggi', 'auto_furgoni': 'Auto e furgoni',
        'moto_ciclomotori': 'Moto e ciclomotori', 'bus_camion': 'Bus e camion',
        'lista_bianca_regolare': 'Passaggi autorizzati regolari',
        'transito_generico_irregolare': 'Transiti irregolari (semantica non documentata)',
        'segnalazioni': 'Segnalazioni',
    },
}


def main():
    d = json.load(open(PATH))
    for ds in d['datasets']:
        slug = ds['slug']
        if slug in META:
            name, desc, source = META[slug]
            ds['name'] = name
            ds['description'] = desc
            ds['source'] = source
        if slug in COLS:
            for c in ds['columns']:
                if c['name'] in COLS[slug]:
                    c['description'] = COLS[slug][c['name']]
    json.dump(d, open(PATH, 'w'), ensure_ascii=False, indent=2)
    print(f'Compilati {len(d["datasets"])} dataset — name/desc/source + colonne chiave.')


if __name__ == '__main__':
    main()
