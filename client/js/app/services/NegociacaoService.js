class NegociacaoService {

	constructor() {

		this._http = new HttpService();
	}

	obterNegociacaoDaSemana() { //callback

		return new Promise((resolve, reject) => { // esse metodo tem que retornar uma promise

			this._http
				.get('negociacoes/semana')
				.then(negociacoes => {
						resolve(negociacoes.map(objeto => new Negociacao(new Date(objeto.data), objeto.quantidade, objeto.valor)));
				})
				.catch(erro => {
					console.log(erro);
					reject('Não foi possível obter as negociações da semana');
				})			
     	}); 

	}
	// obter negociações da semana Anterior
	obterNegociacaoDaSemanaAnterior() { //callback

		return new Promise((resolve, reject) => { // esse metodo tem que retornar uma promise

			this._http
				.get('negociacoes/anterior')
				.then(negociacoes => {
						resolve(negociacoes.map(objeto => new Negociacao(new Date(objeto.data), objeto.quantidade, objeto.valor)));
				})
				.catch(erro => {
					console.log(erro);
					reject('Não foi possível obter as negociações da semana anterior');
				})			
     	}); 

	}
	// obter negociações da semana Retrasada
	obterNegociacaoDaSemanaRetrasada() { //callback

		return new Promise((resolve, reject) => { // esse metodo tem que retornar uma promise

			this._http
				.get('negociacoes/retrasada')
				.then(negociacoes => {
						resolve(negociacoes.map(objeto => new Negociacao(new Date(objeto.data), objeto.quantidade, objeto.valor)));
				})
				.catch(erro => {
					console.log(erro);
					reject('Não foi possível obter as negociações da semana retrasada');
				})			
     	}); 
	}
}