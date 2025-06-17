+++ 
draft = true
date = 2025-06-17T20:09:57+08:00
title = "写一个SmartSql的扩展方法"
description = ""
slug = ""
authors = ['Xu ZhiYi']
tags = ['C#','.Net','SmartSql']
categories = []
externalLink = ""
series = []
+++

# 写一个SmartSql的扩展方法

```C#
/// <summary>
/// 注入仓储结构 By 程序集
/// </summary>
/// <param name="builder"></param>
/// <param name="setupOptions"></param>
/// <returns></returns>
public static SmartSqlDIBuilder AddRepositoryFromAssemblyByFullName(this SmartSqlDIBuilder builder, Action<AssemblyAutoRegisterOptions> setupOptions)
{
    builder.AddRepositoryFactory();
    var options = new AssemblyAutoRegisterOptions
    {
        Filter = type => type.IsInterface
    };
    setupOptions(options);
    ScopeTemplateParser templateParser = new ScopeTemplateParser(options.ScopeTemplate);
    var allTypes = TypeScan.Scan(options);
    foreach (var type in allTypes)
    {
        builder.Services.AddSingleton(type, sp =>
        {
            var sqlMapper = string.IsNullOrEmpty(options.SmartSqlAlias)
                ? sp.EnsureSmartSql().SqlMapper
                : sp.EnsureSmartSql(options.SmartSqlAlias).SqlMapper;
            var factory = sp.GetRequiredService<IRepositoryFactory>();
            var scope = type.FullName?.Replace(".", "_");
            var instance = factory.CreateInstance(type, sqlMapper, scope);
            if (instance.IsDyRepository())
            {
                sqlMapper.SmartSqlConfig.CacheManager.Reset();
            }
            return instance;
        });
    }
    return builder;
}
```