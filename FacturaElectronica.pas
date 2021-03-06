unit FacturaElectronica;

interface

uses FacturaTipos, ComprobanteFiscal;

type

TOnComprobanteGenerado = procedure() of Object;

///<summary>Representa una factura electronica sus metodos para generarla, leerla y validarla
/// cumpliendo la ley del Codigo Fiscal de la Federacion (CFF) Articulos 29 y 29-A.
/// (Soporta la version 2.0 de CFD)</summary>
TFacturaElectronica = class(TFEComprobanteFiscal)
private
  fFolio: TFEFolio;
  fCertificado: TFECertificado;
  fBloqueFolios: TFEBloqueFolios;
  fTipoComprobante: TFeTipoComprobante;
  fExpedidoEn: TFeExpedidoEn;
  fCondicionesDePago: String;
  fEmisor: TFEContribuyente;
  fReceptor: TFEContribuyente;
  fDescuento: Currency;
  sMotivoDescuento: String;
  sMetodoDePago: String;

  fArrConceptos: TFEConceptos;
  fArrImpuestosTrasladados: TFEImpuestosTrasladados;
  fArrImpuestosRetenidos: TFEImpuestosRetenidos;

  // Totales internos
  dSubtotal: Currency;
  dTotal: Currency;

  // Eventos:
  fOnComprobanteGenerado: TOnComprobanteGenerado;
  // Funciones y procedimientos
  procedure LlenarComprobante(iFolio: Integer; fpFormaDePago: TFEFormaDePago);
public
  property Folio: TFEFolio read fFolio write fFolio;
  property Receptor: TFEContribuyente read fReceptor write fReceptor;
  property Emisor: TFEContribuyente read fEmisor write fEmisor;
  property Tipo: TFeTipoComprobante read fTipoComprobante write fTipoComprobante;
  property ExpedidoEn: TFeDireccion read fExpedidoEn write fExpedidoEn;
  property CondicionesDePago: String read fCondicionesDePago write fCondicionesDePago;
  property MetodoDePago: String read sMetodoDePago write sMetodoDePago;
  // Propiedades calculadas por esta clase:
  property SubTotal: Currency read dSubTotal;
  property Conceptos: TFEConceptos read fArrConceptos;
  property ImpuestosRetenidos: TFEImpuestosRetenidos read fArrImpuestosRetenidos;
  property ImpuestosTrasladados: TFEImpuestosTrasladados read fArrImpuestosTrasladados;

  /// <summary>Evento que es llamado inemdiatamente despu�s de que el CFD fue generado,
  /// el cual puede ser usado para registrar en su sistema contable el registro de la factura
  // el cual es un requisito del SAT (Art 29, Fraccion VI)</summary>
  property OnComprobanteGenerado : TOnComprobanteGenerado read fOnComprobanteGenerado write fOnComprobanteGenerado;
  constructor Create(cEmisor, cCliente: TFEContribuyente; bfBloqueFolios: TFEBloqueFolios;
                     cerCertificado: TFECertificado; tcTipo: TFETipoComprobante);
  destructor Destroy; override;
  /// <summary>Agrega un nuevo concepto a la factura, regresa la posicion de dicho concepto en
  /// el arreglo de 'Conceptos'</summary>
  /// <param name="NuevoConcepto">Este es el nuevo concepto a agregar a la factura
  ///   el parametro es un "record" del tipo TFEConcepto.</param>
  function AgregarConcepto(NuevoConcepto: TFeConcepto) : Integer;
  /// <summary>Agrega un nuevo impuesto de retenci�n (ISR, IVA) al comprobante</summary>
  /// <param name="NuevoImpuesto">El nuevo Impuesto con los datos de nombre e importe del mismo</param>
  function AgregarImpuestoRetenido(NuevoImpuesto: TFEImpuestoRetenido) : Integer;
  /// <summary>Agrega un nuevo impuesto de traslado (IVA, IEPS)</summary>
  /// <param name="NuevoImpuesto">El nuevo Impuesto con los datos de nombre, tasa e importe del mismo</param>
  function AgregarImpuestoTrasladado(NuevoImpuesto: TFEImpuestoTrasladado) : Integer;

  //procedure Leer(sRuta: String);
  /// <summary>Genera el archivo XML de la factura electr�nica con el sello, certificado, etc</summary>
  /// <param name="Folio">Este es el numero de folio que tendr� esta factura. Si
  /// es la primer factura, deber� iniciar con el n�mero 1 (Art. 29 Fraccion III)</param>
  /// <param name="fpFormaDePago">Forma de pago de la factura (Una sola exhibici�n o parcialidades)</param>
  /// <param name="sArchivo">Nombre del archivo junto con la ruta en la que se guardar� el archivo XML</param>
  procedure GenerarYGuardar(iFolio: Integer; fpFormaDePago: TFEFormaDePago; sArchivo: String);
  //function esValida() : Boolean;
  /// <summary>Genera la factura en formato cancelado</summary>
  // function Cancelar;
end;

const
	_RFC_VENTA_PUBLICO_EN_GENERAL = 'XAXX010101000';
	_RFC_VENTA_EXTRANJEROS        = 'XEXX010101000';

implementation

uses sysutils, Classes;

constructor TFacturaElectronica.Create(cEmisor, cCliente: TFEContribuyente;
            bfBloqueFolios: TFEBloqueFolios; cerCertificado: TFECertificado; tcTipo: TFETipoComprobante);
begin
    inherited Create;
    dSubtotal := 0;
    // Llenamos las variables internas con las de los parametros
    fEmisor:=cEmisor;
    fReceptor:=cCliente;
    fBloqueFolios:=bfBloqueFolios;
    fCertificado:=cerCertificado;
    fTipoComprobante:=tcTipo;

    // TODO: Implementar CFD 3.0 y usar la version segun sea necesario...
    // Que version de CFD sera usada?
    {if (Now < EncodeDate(2011,1,1)) then
      fComprobante := TFEComprobanteFiscal.Create;
    else
      fVersion:=TFEComprobanteFiscalV3.Create; }
end;

destructor TFacturaElectronica.Destroy();
begin
   inherited Destroy;
end;

function TFacturaElectronica.AgregarImpuestoRetenido(NuevoImpuesto: TFEImpuestoRetenido) : Integer;
begin
    SetLength(fArrImpuestosRetenidos, Length(fArrImpuestosRetenidos) + 1);
    fArrImpuestosRetenidos[Length(fArrImpuestosRetenidos) - 1] := NuevoImpuesto;
    Result:=Length(fArrImpuestosRetenidos) - 1;
end;

function TFacturaElectronica.AgregarImpuestoTrasladado(NuevoImpuesto: TFEImpuestoTrasladado) : Integer;
begin
    SetLength(fArrImpuestosTrasladados, Length(fArrImpuestosTrasladados) + 1);
    fArrImpuestosTrasladados[Length(fArrImpuestosTrasladados) - 1] := NuevoImpuesto;
    Result:=Length(fArrImpuestosTrasladados) - 1;
end;

function TFacturaElectronica.AgregarConcepto(NuevoConcepto: TFEConcepto) : Integer;
begin
    SetLength(fArrConceptos, Length(fArrConceptos) + 1);
    fArrConceptos[Length(fArrConceptos) - 1] := NuevoConcepto;

    // Se Suma el total
    dSubtotal := dSubtotal + NuevoConcepto.Importe;
    dTotal:=dTotal + NuevoConcepto.Importe;

    Result:=Length(fArrConceptos) - 1;
end;

// Funcion encargada de llenar el comprobante fiscal EN EL ORDEN que se especifica en el XSD
// ya que si no es asi, el XML se va llenando en el orden en que se establecen las propiedades de la clase
// haciendo que el comprobante no pase las validaciones del SAT.
procedure TFacturaElectronica.LlenarComprobante(iFolio: Integer; fpFormaDePago: TFEFormaDePago);
var
   I: Integer;
begin
    inherited Emisor:=fEmisor;
    inherited Receptor:=fReceptor;
    // Agregamos todos los conceptos que fueron agregados previamente al arreglo
    for I := 0 to Length(fArrConceptos) - 1 do
         inherited AgregarConcepto(fArrConceptos[I]);

    for I := 0 to Length(fArrImpuestosRetenidos) - 1 do
         inherited AgregarImpuestoRetenido(fArrImpuestosRetenidos[I]);

    for I := 0 to Length(fArrImpuestosTrasladados) - 1 do
         inherited AgregarImpuestoTrasladado(fArrImpuestosTrasladados[I]);

    // TODO: Asignar aqui los complementos y adendas
    inherited BloqueFolios:=fBloqueFolios; // Serie, etc.
    inherited Folio:=iFolio;
    inherited FormaDePago:=fpFormaDePago;
    inherited Certificado:=fCertificado;
    inherited CondicionesDePago:=fCondicionesDePago;
    inherited Subtotal:=dSubtotal;
    inherited AsignarDescuento(fDescuento, sMotivoDescuento);
    inherited MetodoDePago:=sMetodoDePago;
    inherited Tipo:=fTipoComprobante;
end;

procedure TFacturaElectronica.GenerarYGuardar(iFolio: Integer; fpFormaDePago: TFEFormaDePago; sArchivo: String);
begin
     //if ValidarCamposNecesarios() = False then
     //    raise Exception.Create('No todos los campos estan llenos.');

     // Especificamos los campos del CFD en el orden especifico
     // ya que de lo contrario no cumplir� con los requisitios del SAT
     LlenarComprobante(iFolio, fpFormaDePago);

     // Generamos el archivo
     inherited GuardarEnArchivo(sArchivo);

     // Mandamos llamar el evento de que se genero la factura
     if Assigned(fOnComprobanteGenerado) then
        fOnComprobanteGenerado();
end;


end.
