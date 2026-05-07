% 1. Bloco de Notas

% Diretriz, predicado, aridade.
:- dynamic sim/1.
:- dynamic nao/1.
% código imperativo disfarçado?

% 2. Regras de transito do detran
% Fatos que atribuem pesos as infrações

% Aridade 2, atomo, numero
valor_pontos(radar_gravissimo, 7).
valor_pontos(sinal_vermelho, 7).
valor_pontos(racha, 7).
valor_pontos(estacionamento_proibido, 5).
valor_pontos(velocidade_leve, 4).
valor_pontos(bafometro, 7). % pontua, mas gera suspensão direta

% por que separar valor_pontos, ao invés de colocar direto nas regras de suspeito?

suspensao_direta(bafometro).

% 3. Calculo (regras não triviais)
% base nas respostas dadas até o momento
soma_lista([], 0).
soma_lista([Cabeca|Cauda], Total) :-
    soma_lista(Cauda, TotalRestante),
    Total is Cabeca + TotalRestante.

% Pega todas as infrações que o jogador disse "sim" e soma os pontos
pontos_acumulados(Total) :-
    findall(Pts, (sim(Infracao), valor_pontos(Infracao, Pts)), Lista),
    soma_lista(Lista, Total).

% A CNH está suspensa se houve infração direta OU soma >= 20
status_cnh_suspensa :-
    sim(Infracao), suspensao_direta(Infracao), !.
status_cnh_suspensa :-
    pontos_acumulados(Total),
    Total >= 20.

% Validações silenciosas para o jogo usar como condição de vitoria
verifica_cnh_suspensa :-
    status_cnh_suspensa,
    pontos_acumulados(Total),
    format('~n[DEDUCAO LOGICA: O sistema detectou que a CNH estourou o limite ou teve suspensao direta (~w pts)]~n', [Total]).

verifica_cnh_regular :-
    \+ status_cnh_suspensa, % \+ é negação (se a suspensão falhar, a CNH é regular)
    pontos_acumulados(Total),
    format('~n[DEDUCAO LOGICA: O sistema confirmou que a CNH esta regular (~w pts no sistema)]~n', [Total]).

% 4. Arvore de decisão dos suspeitos
% provar esses fatos de cima para baixo

culpado(pedro) :-
    verifica(carro_prata),
    verifica(tem_mais_de_30_anos),
    verifica(radar_gravissimo),
    verifica(sinal_vermelho),
    verifica(racha),
    verifica_cnh_suspensa. 

culpado(maria) :-
    verifica(carro_prata),
    verifica(e_jovem_adulto),
    verifica(radar_gravissimo),
    verifica(estacionamento_proibido),
    verifica_cnh_regular. 

culpado(lucas) :-
    verifica(carro_prata),
    verifica(e_jovem_adulto),
    verifica(bafometro),
    verifica_cnh_suspensa. 

culpado(ana) :-
    verifica(carro_preto),
    verifica(tem_mais_de_30_anos),
    verifica(bafometro),
    verifica_cnh_suspensa. 

culpado(carlos) :-
    verifica(carro_preto),
    verifica(tem_mais_de_30_anos),
    verifica(sinal_vermelho),
    verifica(estacionamento_proibido),
    verifica(velocidade_leve),
    verifica_cnh_regular. 

culpado(joao) :-
    verifica(carro_preto),
    verifica(e_jovem_adulto),
    verifica(estacionamento_proibido),
    verifica(velocidade_leve),
    verifica_cnh_regular.

% 5. Dicionario de perguntas
texto_pergunta(carro_prata, 'dirigia um carro prata').
texto_pergunta(carro_preto, 'dirigia um carro preto').
texto_pergunta(tem_mais_de_30_anos, 'aparenta ter mais de 30 anos').
texto_pergunta(e_jovem_adulto, 'e um jovem adulto (18 a 30 anos)').
texto_pergunta(radar_gravissimo, 'foi pego em um radar acima de 50% do limite (Infracao Gravissima)').
texto_pergunta(sinal_vermelho, 'ultrapassou o sinal vermelho (Infracao Gravissima)').
texto_pergunta(racha, 'foi pego disputando corrida ilegal / racha (Infracao Gravissima)').
texto_pergunta(bafometro, 'recusou o teste do bafometro / embriaguez').
texto_pergunta(estacionamento_proibido, 'estacionou em local proibido (Infracao Grave)').
texto_pergunta(velocidade_leve, 'passou um pouco acima da velocidade permitida (Infracao Leve)').

% 6. Entrada/Saída e interação (com exclusão mútua lógica)
verifica(Atributo) :-
    sim(Atributo), !.

verifica(Atributo) :-
    nao(Atributo), !, fail.

verifica(Atributo) :-
    perguntar(Atributo).

perguntar(Atributo) :-
    (texto_pergunta(Atributo, TextoFormatado) -> VerdadeiroTexto = TextoFormatado ; VerdadeiroTexto = Atributo),
    format('O suspeito ~w? (sim/nao): ', [VerdadeiroTexto]),
    read(Resposta),
    processar_resposta(Atributo, Resposta).

% Regras de exclusão mútua:
% Se o jogador disser "sim" para uma propriedade, o Prolog deduz o "nao" da propriedade oposta.

processar_resposta(carro_prata, sim) :-
    asserta(sim(carro_prata)),
    asserta(nao(carro_preto)), !. % O corte (!) impede que o Prolog teste a regra genérica abaixo

processar_resposta(carro_preto, sim) :-
    asserta(sim(carro_preto)),
    asserta(nao(carro_prata)), !.

processar_resposta(tem_mais_de_30_anos, sim) :-
    asserta(sim(tem_mais_de_30_anos)),
    asserta(nao(e_jovem_adulto)), !.

processar_resposta(e_jovem_adulto, sim) :-
    asserta(sim(e_jovem_adulto)),
    asserta(nao(tem_mais_de_30_anos)), !.

% Regra Generica:
% Para as infrações que não são mutuamente exclusivas
processar_resposta(Atributo, sim) :-
    asserta(sim(Atributo)).

processar_resposta(Atributo, nao) :-
    asserta(nao(Atributo)),
    fail.

% 7. Controle Principal
jogar :-
    limpar_memoria,
    format('~n=== DETETIVE DE TRANSITO ===~n'),
    format('Vou fazer perguntas sobre as infracoes. Eu calcularei as penalidades sozinho.~n'),
    format('Responda com "sim." ou "nao." (nao esqueca do ponto final!).~n~n'),
    (   culpado(Suspeito) ->
        format('~n>>> VITORIA: O culpado e ~w! <<<~n~n', [Suspeito])
    ;   format('~n>>> FALHA: As pistas nao batem com nenhum suspeito. <<<~n~n')
    ),
    limpar_memoria.

limpar_memoria :-
    retractall(sim(_)),
    retractall(nao(_)).
