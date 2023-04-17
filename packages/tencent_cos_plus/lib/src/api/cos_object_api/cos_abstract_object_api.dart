import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart';

import '../../model/model.dart';
import '../cos_abstract_api.dart';
import '../cos_api_mixin.dart';

/// Object接口
/// https://cloud.tencent.com/document/product/436/7749
abstract class COSAbstractObjectApi extends COSAbstractApi with COSApiMixin {
  COSAbstractObjectApi(
    super.config, {
    required this.bucketName,
    required this.region,
  });

  /// 存储桶，COS 中用于存储数据的容器
  final String bucketName;

  /// 地域信息，枚举值可参见 可用地域 文档，例如：ap-beijing、ap-hongkong、eu-frankfurt 等
  final String region;

  /// 拼接BaseApiUrl
  /// [bucketName] 存储桶
  /// [region] 区域信息
  String getBaseApiUrl([String? bucketName, String? region]) {
    return 'https://${bucketName ?? this.bucketName}-${config.appId}.cos.'
        '${region ?? this.region}.myqcloud.com';
  }

  /// GET Bucket 请求等同于 List Objects 请求，可以列出该存储桶内的部分或者全部对象。
  /// [bucketName]
  /// [region]
  /// [listObjectHeader]
  Future<COSListBucketResult> listObjects({
    String? bucketName,
    String? region,
    COSListObjectHeader? listObjectHeader,
  }) async {
    final Response response = await client.get(
      '${getBaseApiUrl(bucketName, region)}/',
      queryParameters: listObjectHeader?.toMap(),
    );
    return toXml<COSListBucketResult>(response)(COSListBucketResult.fromXml);
  }

  /// GET Bucket Object versions 接口用于拉取存储桶内的所有对象及其历史版本信息，
  /// 您可以通过指定参数筛选出存储桶内部分对象及其历史版本信息
  /// [bucketName]
  /// [region]
  /// [listObjectHeader]
  Future<COSListVersionsResult> listObjectVersions({
    String? bucketName,
    String? region,
    COSListObjectHeader? listObjectHeader,
  }) async {
    final Response response = await client.get(
      '${getBaseApiUrl(bucketName, region)}/?versions',
      queryParameters: listObjectHeader?.toMap(),
    );
    return toXml<COSListVersionsResult>(response)(
        COSListVersionsResult.fromXml);
  }

  /// PUT Object 接口请求可以将本地的对象（Object）上传至指定存储桶中
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [objectValue]
  /// [contentType]
  /// [headers]
  Future<Response> putObject({
    String? bucketName,
    String? region,
    required String objectKey,
    List<int>? objectValue,
    String? contentType,
    COSACLHeader? aclHeader,
    Map<String, String> headers = const <String, String>{},
  }) async {
    assert((objectValue != null && contentType != null) ||
        (objectValue == null && contentType == null));

    final Map<String, String> newHeaders = Map.of(headers);
    if (aclHeader != null) {
      newHeaders.addAll(aclHeader.toMap());
    }
    if (objectValue != null && contentType != null) {
      final String md5String =
          Base64Encoder().convert(md5.convert(objectValue).bytes).toString();
      newHeaders['Content-Type'] = contentType;
      newHeaders['Content-Length'] = objectValue.length.toString();
      newHeaders['Content-MD5'] = md5String;
    }
    final Response response = await client.put(
      '${getBaseApiUrl(bucketName, region)}/$objectKey',
      headers: newHeaders,
      body: objectValue,
    );
    return toValidation(response);
  }

  /// PUT Object - Copy 接口请求创建一个已存在 COS 的对象的副本，即将一个对象从源路径（对象键）复制到目标路径（对象键）
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [xCOSCopySource]
  /// [contentType]
  /// [headers]
  Future<COSCopyObjectResult> putObjectCopy({
    String? bucketName,
    String? region,
    required String objectKey,
    required String xCOSCopySource,
    required String contentType,
    COSACLHeader? aclHeader,
    Map<String, String> headers = const <String, String>{},
  }) async {
    final Map<String, String> newHeaders = Map.of(headers);
    if (aclHeader != null) {
      newHeaders.addAll(aclHeader.toMap());
    }
    newHeaders['x-cos-copy-source'] = xCOSCopySource;
    newHeaders['Content-Type'] = contentType;
    final Response response = await client.put(
      '${getBaseApiUrl(bucketName, region)}/$objectKey',
      headers: newHeaders,
    );
    return toXml<COSCopyObjectResult>(response)(COSCopyObjectResult.fromXml);
  }

  /// GET Object GET Object 接口请求可以将 COS 存储桶中的对象（Object）下载至本地
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [getObjectQuery]
  /// [headers]
  Future<Response> getObject({
    String? bucketName,
    String? region,
    required String objectKey,
    COSGetObjectQuery? getObjectQuery,
    Map<String, String> headers = const <String, String>{},
  }) async {
    final Response response = await client.get(
      '${getBaseApiUrl(bucketName, region)}/$objectKey',
      queryParameters: getObjectQuery?.toMap(),
    );
    return toValidation(response);
  }

  /// POST Object 接口请求可以将本地不超过5GB的对象（Object）以网页表单（HTML Form）的形式上传至指定存储桶中
  // Future<Response> postObject({
  //   String? bucketName,
  //   String? region,
  //   required String key,
  // }) async {}

  /// HEAD Object 接口请求可以判断指定对象是否存在和有权限，并在指定对象可访问时获取其元数据
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [versionId]
  /// [headers]
  Future<Response> headObject({
    String? bucketName,
    String? region,
    required String objectKey,
    String? versionId,
    Map<String, String> headers = const <String, String>{},
  }) async {
    final Response response = await client.head(
      '${getBaseApiUrl(bucketName, region)}/$objectKey',
      headers: headers,
      queryParameters: <String, String>{
        if (versionId != null) 'versionId': versionId
      },
    );
    return toValidation(response);
  }

  /// DELETE Object 接口请求可以删除一个指定的对象（Object）
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [versionId]
  Future<Response> deleteObject({
    String? bucketName,
    String? region,
    required String objectKey,
    String? versionId,
  }) async {
    final Response response = await client.delete(
      '${getBaseApiUrl(bucketName, region)}/$objectKey',
      queryParameters: <String, String>{
        if (versionId != null) 'versionId': versionId
      },
    );
    return toValidation(response);
  }

  /// DELETE Multiple Objects 接口请求可以批量删除指定存储桶中的多个对象（Object），单次请求支持最多删除1000个对象
  /// [bucketName]
  /// [region]
  /// [delete]
  Future<COSDeleteResult> deleteMultipleObjects({
    String? bucketName,
    String? region,
    required COSDelete delete,
  }) async {
    Map<String, String> headers = <String, String>{};
    final String xmlString = delete.toXmlString();
    // http 框架设置body时，会自动给 Content-Type 指定字符集为 charset=utf-8
    // 设置 application/xml; charset=utf-8 保持一致
    headers['Content-Type'] = 'application/xml; charset=utf-8';
    headers['Content-Length'] = xmlString.length.toString();
    final String md5String = Base64Encoder()
        .convert(md5.convert(xmlString.codeUnits).bytes)
        .toString();
    headers['Content-MD5'] = md5String;
    final Response response = await client.post(
      '${getBaseApiUrl(bucketName, region)}/?delete',
      headers: headers,
      body: xmlString,
    );
    return toXml<COSDeleteResult>(response)(COSDeleteResult.fromXml);
  }

  /// OPTIONS Object 用于跨域资源共享（CORS）的预检（Preflight）请求
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [origin]
  /// [accessControlRequestMethod]
  /// [accessControlRequestHeaders]
  Future<Response> optionsObject({
    String? bucketName,
    String? region,
    required String objectKey,
    required String origin,
    required String accessControlRequestMethod,
    String? accessControlRequestHeaders,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Origin': origin,
      'Access-Control-Request-Method': accessControlRequestMethod,
      if (accessControlRequestHeaders != null)
        'Access-Control-Request-Headers': accessControlRequestHeaders,
    };
    final Response response = await client.options(
      '${getBaseApiUrl(bucketName, region)}/$objectKey',
      headers: headers,
    );
    return toValidation(response);
  }

  /// POST Object restore 接口请求可以对一个归档存储或深度归档存储类型的对象进行恢复（解冻）
  /// 以便读取该对象内容，恢复出的可读取对象是临时的，您可以设置需要保持可读以及随后删除该临时副本的时间
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [restoreRequest]
  Future<Response> postObjectRestore({
    String? bucketName,
    String? region,
    required String objectKey,
    required COSRestoreRequest restoreRequest,
  }) async {
    Map<String, String> headers = <String, String>{};
    final String xmlString = restoreRequest.toXmlString();
    // http 框架设置body时，会自动给 Content-Type 指定字符集为 charset=utf-8
    // 设置 application/xml; charset=utf-8 保持一致
    headers['Content-Type'] = 'application/xml; charset=utf-8';
    headers['Content-Length'] = xmlString.length.toString();
    final String md5String = Base64Encoder()
        .convert(md5.convert(xmlString.codeUnits).bytes)
        .toString();
    headers['Content-MD5'] = md5String;
    final Response response = await client.post(
      '${getBaseApiUrl(bucketName, region)}/$objectKey?restore',
      body: xmlString,
    );
    return toValidation(response);
  }

  /// 上传文件对象
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [filePath]
  /// [headers]
  Future<Response> putFileObject({
    String? bucketName,
    String? region,
    required String objectKey,
    required String filePath,
    COSACLHeader? aclHeader,
    Map<String, String> headers = const <String, String>{},
  });

  /// 上传文件夹对象
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [headers]
  Future<Response> putFolderObject({
    String? bucketName,
    String? region,
    required String objectKey,
    COSACLHeader? aclHeader,
    Map<String, String> headers = const <String, String>{},
  }) {
    return putObject(
      bucketName: bucketName,
      region: region,
      objectKey: objectKey,
      headers: headers,
    );
  }

  /// 上传目录
  /// [bucketName]
  /// [region]
  /// [directory]
  /// [headers]
  Future<bool> putDirectory({
    String? bucketName,
    String? region,
    required String directory,
    Map<String, String> headers = const <String, String>{},
  });

  /// 删除目录
  /// [bucketName]
  /// [region]
  /// [directory]
  Future<bool> deleteDirectory({
    String? bucketName,
    String? region,
    required String directory,
  }) async {
    try {
      final COSListBucketResult buckets = await listObjects(
        bucketName: bucketName,
        region: region,
        listObjectHeader: COSListObjectHeader()..prefix = directory,
      );
      if (buckets.contents?.isNotEmpty ?? false) {
        final List<COSObject> objects =
            buckets.contents!.map<COSObject>((COSContents content) {
          return COSObject(key: content.key ?? '');
        }).toList();
        final COSDelete delete = COSDelete(quiet: false, objects: objects);
        await deleteMultipleObjects(
          bucketName: bucketName,
          region: region,
          delete: delete,
        );
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// PUT Object acl 接口用来写入对象的访问控制列表（ACL），
  /// 您可以通过请求头x-cos-acl和x-cos-grant-*传入 ACL 信息，或者通过请求体以 XML 格式传入 ACL 信息。
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [aclHeader]
  /// [accessControlPolicy]
  Future<Response> putObjectACL({
    String? bucketName,
    String? region,
    required String objectKey,
    COSACLHeader? aclHeader,
    COSAccessControlPolicy? accessControlPolicy,
  }) async {
    Map<String, String>? headers;
    if (aclHeader != null) {
      headers ??= aclHeader.toMap();
    }
    String? xmlString;
    if (accessControlPolicy != null) {
      headers ??= <String, String>{};
      xmlString = accessControlPolicy.toXmlString();
      // http 框架设置body时，会自动给 Content-Type 指定字符集为 charset=utf-8
      // 设置 application/xml; charset=utf-8 保持一致
      headers['Content-Type'] = 'application/xml; charset=utf-8';
      headers['Content-Length'] = xmlString.length.toString();
      final String md5String = Base64Encoder()
          .convert(md5.convert(xmlString.codeUnits).bytes)
          .toString();
      headers['Content-MD5'] = md5String;
    }

    final Response response = await client.put(
      '${getBaseApiUrl(bucketName, region)}/$objectKey?acl',
      headers: headers,
      body: xmlString,
    );
    return toValidation(response);
  }

  /// GET Object acl 接口用来获取对象的访问控制列表（ACL）。该 API 的请求者需要对指定对象有读取 ACL 权限。
  /// [bucketName]
  /// [region]
  /// [objectKey]
  Future<COSAccessControlPolicy> getObjectACL({
    String? bucketName,
    String? region,
    required String objectKey,
  }) async {
    final Response response =
        await client.get('${getBaseApiUrl(bucketName, region)}/$objectKey?acl');
    return toXml<COSAccessControlPolicy>(response)(
        COSAccessControlPolicy.fromXml);
  }

  /// COS 支持为已存在的对象设置标签。PUT Object tagging 接口通过为对象添加键值对作为对象标签，可以协助您分组管理已有的对象资源
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [tagging]
  /// [versionId]
  Future<Response> putObjectTagging({
    String? bucketName,
    String? region,
    required String objectKey,
    required COSTagging tagging,
    String? versionId,
  }) async {
    final Map<String, String> headers = <String, String>{};
    final String xmlString = tagging.toXmlString();
    // http 框架设置body时，会自动给 Content-Type 指定字符集为 charset=utf-8
    // 设置 application/xml; charset=utf-8 保持一致
    headers['Content-Type'] = 'application/xml; charset=utf-8';
    headers['Content-Length'] = xmlString.length.toString();
    final String md5String = Base64Encoder()
        .convert(md5.convert(xmlString.codeUnits).bytes)
        .toString();
    headers['Content-MD5'] = md5String;
    final Response response = await client.put(
      '${getBaseApiUrl(bucketName, region)}/$objectKey?tagging',
      headers: headers,
      queryParameters: <String, String>{
        if (versionId != null) 'versionId': versionId,
      },
      body: xmlString,
    );
    return toValidation(response);
  }

  /// GET Object tagging 接口用于查询指定对象下已有的对象标签。
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [versionId]
  Future<COSTagging> getObjectTagging({
    String? bucketName,
    String? region,
    required String objectKey,
    String? versionId,
  }) async {
    final Response response = await client.get(
      '${getBaseApiUrl(bucketName, region)}/$objectKey?tagging',
      queryParameters: <String, String>{
        if (versionId != null) 'versionId': versionId,
      },
    );
    return toXml<COSTagging>(response)(COSTagging.fromXml);
  }

  /// DELETE Object tagging 接口用于删除指定对象下已有的对象标签。
  /// [bucketName]
  /// [region]
  /// [objectKey]
  /// [versionId]
  Future<Response> deleteObjectTagging({
    String? bucketName,
    String? region,
    required String objectKey,
    String? versionId,
  }) async {
    final Response response = await client.delete(
      '${getBaseApiUrl(bucketName, region)}/$objectKey?tagging',
      queryParameters: <String, String>{
        if (versionId != null) 'versionId': versionId,
      },
    );
    return toValidation(response);
  }
}
