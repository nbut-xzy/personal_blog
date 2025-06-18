+++ 
draft = false
date = 2025-06-17T20:09:57+08:00
title = "SmartSql 多数据库场景下简化 Repository 命名与准确加载 XML SQL 的扩展方法"
description = ""
slug = ""
authors = ['Xu ZhiYi']
tags = ['C#','.Net','SmartSql']
categories = []
externalLink = ""
series = []
+++

# SmartSql 多数据库场景下简化 Repository 命名与准确加载 XML SQL 的扩展方法

在多数据库项目中，我们通常会使用多个 SmartSql 实例。每个实例又管理着众多对应数据表的 Repository。

默认的 ```AddRepositoryFromAssembly()``` 方法加载 Repository 时，仅能通过类名定位对应 Scope 的 XML 文件。这导致了一个问题：为了区分不同数据库表对应的 Repository 类，我们不得不使用冗长的类名，严重影响了开发体验。

为此，我编写了一个自定义扩展方法作为替代方案。该方法的核心是：通过反射获取 Repository 类的完整名称 (FullName)。由于 SmartSql 的 Scope 部分不支持点号 (```.```)，需要将 FullName 中的点号替换为下划线 (```_```)。最后，使用转换后的名称去加载对应 Scope 的 XML 文件。

这种方式的优势在于：位于不同类库中的 Repository，现在可以使用相同或更简短的类名了。

```C#
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